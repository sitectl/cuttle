#!/usr/bin/python

import json
import math
import numpy as np
import os
import sys, getopt

from collections import OrderedDict

matrixA = None
matrixB = None
coeffs = None
reserve_total = None
used_bytes = None
last_index = None
last_weekday = None
last_host_count = None
last_debug_ratio = None
last_num_all_msg = None

desired_hostnum = 50
days_ahead = 90
retention_days = 270

def calculate_coeffs():
    global matrixA, matrixB, coeffs, reserve_total, used_bytes, \
        last_debug_ratio, last_num_all_msg
    # retrieve file that was created in collection script
    with open('/opt/sitecontroller/elk-stats-output/elk-stats.json', 'r') as f:
        data = json.load(f)
    reserve_total = data[1]["reserve_total"]
    used_bytes = data[1]["used_bytes"]
    data = sorted(data[0].iteritems(), key=lambda x: x[1])
    row_length = len(data)
    matrixA = np.ones(shape=(row_length, 5))
    matrixB = np.zeros(shape=(row_length, 1))
    is_singular = True
    for i, index in enumerate(data):
        matrixA[i][1] = data[i][1]["day_index"]
        matrixA[i][2] = data[i][1]["weekday"]
        matrixA[i][3] = data[i][1]["total_host_count"]
        matrixA[i][4] = data[i][1]["log(x)"]
        matrixB[i] = data[i][1]["total_size"]
        if is_singular is True and i != 0:
            if matrixA[i][3] != matrixA[i-1][3]:
                is_singular = False
        
    last_debug_ratio = data[row_length-2][1]["total_debug_ratio"]
    last_num_all_msg = data[row_length-2][1]["total_num_of_all_messages"]
    if is_singular and row_length > 2:
        if matrixB[0] <= matrixB[1]:
            matrixA[0][3] -= 0.01
        else:
            matrixA[0][3] += 0.01

    # remove current day's index; it isn't complete
    matrixA = matrixA[:-1]
    matrixB = matrixB[:-1]
    matrixAt = np.transpose(matrixA)
    matrixAtA = np.dot(matrixAt, matrixA)
    matrixAtB = np.dot(matrixAt, matrixB)
    matrixInverseAtA = np.linalg.inv(matrixAtA)

    # these are the magic numbers
    coeffs = np.dot(matrixInverseAtA, matrixAtB)

    return matrixA, matrixB, coeffs


def predict():
    global last_index, last_weekday, last_host_count
    day_index_vector_sum = 0
    weekday_vector_sum = 0
    function_vector_sum = 0
    current_sum = 0
    last_index = matrixA[-1, 1]
    last_weekday = matrixA[-1, 2]
    last_host_count = matrixA[-1, 3]

    # create data points for future indices  :: days_ahead, retention, last_index
    i = 0
    num_of_predicted = 0
    if (last_index + days_ahead - retention_days) < last_index:
        while (matrixA[i,1] <= (last_index + days_ahead - retention_days)):
            i += 1
    else:
        i = last_index + days_ahead - retention_days
    for j in range(int(i), int(last_index + days_ahead + 1)):
        if j < matrixB.size:
            current_sum += matrixB[j]
        else:
            day_index_vector_sum += j
            weekday_vector_sum += ((j + last_weekday) % 7) + 1
            function_vector_sum += (math.log10(j + 4) / math.pow(j, 1.0/3.0))
            num_of_predicted += 1

    # (1) prediction of total bytes used based on last_host_count
    # days into the future
    future_sum = \
        current_sum + \
        coeffs[0] * num_of_predicted + \
        coeffs[1] * day_index_vector_sum + \
        coeffs[2] * weekday_vector_sum + \
        coeffs[3] * last_host_count * num_of_predicted + \
        coeffs[4] * function_vector_sum
    # This is a fail-safe should the prediction be negative (impossible).
    # The trend which leads to negative values implies the sizes are only
    #  being reduced. To avoid these nonsensical values, we can at least
    #  say that they will be less than or equal to the current total size
    #  of the cluster. To reduce risk, we assume that it will remain constant,
    #  it current projected local maximum.
    days_at_future_point = retention_days
    if retention_days > days_ahead + last_index:
        days_at_future_point = days_ahead + last_index
    if future_sum[0] <  (days_at_future_point * (math.pow(1024.0, 3.0) / 10.0)):
        future_sum = np.array([used_bytes])

    # (2) prediction of number of hosts we are able to maintain with current
    # storage
    host_projection = \
        reserve_total - current_sum - \
        coeffs[0] * num_of_predicted - \
        coeffs[1] * day_index_vector_sum - \
        coeffs[2] * weekday_vector_sum - \
        coeffs[4] * function_vector_sum
    host_projection = host_projection / (coeffs[3] * num_of_predicted)
    # A nonnegative number is the only realistic value here
    if host_projection < 0:
        host_projection = np.array([0])

    # Fail-safe for unusually large value for hosts sustainable.
    # Currently set at 1000, subject to change if/when we're amazing.
    if host_projection > 1000:
        host_projection = np.array([1000])

    # (3) prediction of total bytes used based on desired_hostnum
    # (similar to 1, kept separate for output)
    host_sum = \
        current_sum + \
        coeffs[0] * num_of_predicted + \
        coeffs[1] * day_index_vector_sum + \
        coeffs[2] * weekday_vector_sum + \
        coeffs[3] * desired_hostnum * num_of_predicted + \
        coeffs[4] * function_vector_sum
    # same fail-safe case as (1)
    if host_sum <  (days_at_future_point * (math.pow(1024.0, 3.0) / 8.0)):
        host_sum = np.array([used_bytes])

    # (4) prediction of day left until max capacity will be reached
    remaining_sum = reserve_total - used_bytes
    j = last_index + 1  # pointer for last predicted index number
    i = 0   # pointer for first index or
            # last index minus retention (existing or predicted)

    while (remaining_sum > 0):  # calculates rolling total
        if j > retention_days:
            if i < matrixB.size:
                remaining_sum += matrixB[i]
            else:
                remaining_sum += evaluate_point(i)
            i += 1
        remaining_sum -= evaluate_point(j)
        j += 1
        if j > 1000:
            remaining_sum = "1000"
            break
    if remaining_sum != "1000":
        remaining_sum = j - last_index - 2

    return future_sum, host_projection, host_sum, remaining_sum


def evaluate_point(p):  # evaluates prediction function at single point
    evaluated_point = (
            coeffs[0] + \
            coeffs[1] * p + \
            coeffs[2] * (((p + last_weekday) % 7) + 1) + \
            coeffs[3] * last_host_count + \
            coeffs[4] * (math.log10(p + 4) / math.pow(p, 1.0/3.0))
    )
    return evaluated_point


def main(argv):
    global desired_hostnum, days_ahead, retention_days
    days = ""
    hosts = ""
    outfile = "/opt/sitecontroller/elk-stats-output/elk-stats-summary.json"
    retention = ""
    try:
        opts, args = getopt.getopt(argv,"hd:n:f:r:",["days=","hosts=","outfile=","retention="])
    except getopt.GetoptError:
        print 'elk-stats.py -d <days_into_future> -n <number_of_hosts> \
-r <retention_days> -f <output_file>'
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print 'elk-stats.py -d <days_into_future> -n <number_of_hosts> \
-r <retention_days> -f <output_file>'
            sys.exit()
        elif opt in ("-d", "--days"):
            days = arg
        elif opt in ("-n", "--hosts"):
            hosts = arg
        elif opt in ("-r", "--retention"):
             retention = arg
        elif opt in ("-f", "--file"):
            outfile = arg

    # calculate coefficients for prediction model
    calculate_coeffs()

    # number of hosts to predict size with
    if days is not "":
        days_ahead = int(days)
    if hosts is not "":
        desired_hostnum = int(hosts)
    if retention is not "":
        retention_days = int(retention)
    if outfile[-5:] != ".json":
        outfile = outfile + '.json'
    # calculate estimations using prediction model
    future_sum, host_projection, host_sum, remaining_sum = \
        predict()
    terabyte = math.pow(1024, 4.0)
    gigabyte = math.pow(1024, 3.0)
    future_sum = future_sum[0] / terabyte
    host_sum = host_sum[0] / terabyte
    output = [
        ("Current Projected Size", future_sum),
        ("Desired-Host Projected Size", host_sum),
        ("Max Hosts Sustainable", host_projection[0]),
        ("Days Remaining Until Max Capacity Reached", remaining_sum),
        ("Coefficients", coeffs.flatten().tolist()),
        ("Last Index Number", last_index),
        ("Last Weekday", last_weekday),
        ("Last Host Count", last_host_count),
        ("Last Index Size", matrixB[-1][0] / gigabyte),
        ("Last Number of All Messages in a Day", last_num_all_msg),
        ("Last Debug Ratio", last_debug_ratio),
        ("Retention Days", retention_days)
        ]

    # output json and stdout summary
    summary = {}
    for pair in output:
        summary[pair[0]] = pair[1]
    with open(outfile, 'w') as f:
        json.dump(summary, f, indent=4, sort_keys=True, separators=(',', ':'))
        f.close()

    return summary


if __name__ == "__main__":
    main(sys.argv[1:])
