#!/usr/bin/python

import datetime
import math
import json

from collections import OrderedDict
from elasticsearch import Elasticsearch
es = Elasticsearch(timeout=30)

index_data = {}
DATAFILE = '/opt/sitecontroller/elk-stats-output/elk-stats.json'
# determine what indices we have to work with
ls_indices = es.indices.get(index="logstash-2*")
cs_indices = es.indices.get(index="cleversafe-2*")
num_of_days = len(ls_indices)
# dict of all indices
all_indices = []
all_indices.extend(ls_indices)
all_indices.extend(cs_indices)
all_indices = sorted(all_indices, key=lambda t: t[-10:])
cluster_data = es.cluster.stats()
used_bytes = cluster_data["nodes"]["fs"]["total_in_bytes"] -\
    cluster_data["nodes"]["fs"]["free_in_bytes"]
reserve_total = used_bytes + cluster_data["nodes"]["fs"]["available_in_bytes"]


def construct_data():
    first_day = None
    # for each index, get the stats we care about
    for index in all_indices:
        data = es.indices.stats(index=index)

        # filter out indices of absurdly small size
        if data["indices"][index]["total"]["store"]["size_in_bytes"]\
                < 1000000:
            continue

        # initialize index data set
        date_title = index[-10:]
        if date_title not in index_data:
            index_data[date_title] = \
                {
                    "date": None,
                    "day_index": None,
                    "indices":{},
                    "log(x)": None,
                    "total_debug_ratio": 0,
                    "total_host_count": 0,
                    "total_num_of_all_messages": 0,
                    "total_num_of_debug_messages": 0,
                    "total_size": 0,
                    "weekday": None
                }

            # get day index num.
            day = datetime.datetime.strptime(
                (date_title).replace(".", "/"), '%Y/%m/%d'
                )
            if first_day is None:
                first_day = day
            day_index = (day - first_day).days + 1
            weekday = day.isoweekday()

            # index date, number, and weekday, respectively
            index_data[date_title]["date"] = date_title.replace(".", "/")
            index_data[date_title]["day_index"] = day_index
            index_data[date_title]["weekday"] = weekday

            # index log(x) function of index number
            # Addition of 4 came about to avoid vertical asymptote, and shift
            # right, giving overall smoothness.
            # The division of the cubed root of x gave way to a function with
            # horizontal asymptote at 0, continuous growth or reduction that
            # diminishes over time, but is never eliminated.
            # In my opinion, better than simple linear analysis of variables
            # since this will adjust, rather than over or under predict.
            index_data[date_title]["log(x)"] = \
                (math.log10(index_data[date_title]["day_index"] + 4)) / \
                (math.pow(index_data[date_title]["day_index"], 1.0/3.0))

        index_data[date_title]["indices"][index] = {}

        # size in bytes of index
        index_data[date_title]["indices"][index]["size"] = \
            data["indices"][index]["total"]["store"]["size_in_bytes"]
        index_data[date_title]["total_size"] += \
            index_data[date_title]["indices"][index]["size"]

        # ES queries to find host count on given day
        # Searches placed in 'queries' long-to-short (in time)
        # Timeout relative to size of cluster
        timeout = 10.0 + ((used_bytes / math.pow(1024, 4.0)) * 2.5)
        # queries:
        # 1) all messages, 2) "DEBUG" messages, 3) "TRACE" messages, 4) host #
        # msearch requires empy queries at beginning and between each.
        queries = [
            {},
            {
                "query": {
                    "match_all": {}
                },
                "timeout":timeout
            },
            {},
            {
                "query": {
                    "match": {
                        "message": "DEBUG"
                    }
                },
                "timeout": timeout
            },
            {},
            {
                "query": {
                    "match": {
                        "message": "TRACE"
                    }
                },
                "timeout": timeout
            },
            {},
            {
                "aggs": {
                    "host_count": {
                        "cardinality": {
                            "field": "host"
                        }
                    }
                },
                "timeout": timeout
            }
        ]
        data = es.msearch(index=str(index), body=queries, search_type="query_then_fetch")

        # the responses from the multiple queries
        data = data["responses"]
        num_of_all_messages = data[0]['hits']['total']

        # Debug messages + Trace messages
        index_data[date_title]["indices"][index]["num_of_debug_messages"] = \
            data[1]['hits']['total'] + data[2]['hits']['total']
        index_data[date_title]["total_num_of_debug_messages"] += \
            index_data[date_title]["indices"][index]["num_of_debug_messages"]

        # index host count
        index_data[date_title]["indices"][index]["host_count"] = \
            data[3]["aggregations"]["host_count"]["value"]
        index_data[date_title]["total_host_count"] += \
            index_data[date_title]["indices"][index]["host_count"]

        # All messages
        index_data[date_title]["indices"][index]["num_of_all_messages"] = num_of_all_messages
        index_data[date_title]["total_num_of_all_messages"] += \
            index_data[date_title]["indices"][index]["num_of_all_messages"]

        debug_ratio = \
            float(index_data[date_title]["indices"][index]["num_of_debug_messages"]) / \
            float(num_of_all_messages)
        index_data[date_title]["indices"][index]["debug_ratio"] = debug_ratio
        index_data[date_title]["total_debug_ratio"] = \
            float(index_data[date_title]["total_num_of_debug_messages"]) / \
            float(index_data[date_title]["total_num_of_all_messages"])

    cluster_data = {}
    cluster_data["reserve_total"] = reserve_total
    cluster_data["used_bytes"] = used_bytes
    # it puts the index in its file...
    with open(DATAFILE, 'w') as f:
        json.dump([index_data,cluster_data], f, sort_keys=True, indent=4,
                  separators=(',', ': '))
    return


def main():
    construct_data()


if __name__ == "__main__":
    main()
