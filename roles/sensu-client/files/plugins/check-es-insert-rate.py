#!/usr/bin/python

from __future__ import division
import argparse
import time
import pyes


###CONSTANTS###
OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3
###END CONSTANTS###


class Calculator():
    '''This is our main class. It takes results from Elasticsearch and from what was previously recorded
    and can give the text to be printed and the exit code'''
    def __init__(self, warn, crit, myfile='/tmp/check_es_insert', myaddress='localhost:9200', threshold='lt', index=''):
        self.warn = warn
        self.crit = crit
        self.my_elasticsearcher = Elasticsearcher(address=myaddress)
        self.my_disker = Disker(file=myfile)
        self.threshold = threshold
        self.index = index
    def calculate(self, old_value, new_value, old_time, new_time):
        '''Calculates the number of inserts per second since the last recording'''
        return (new_value - old_value)/(new_time - old_time)
    def getPrevious(self):
        '''Gets the previously recorded number of documents and UNIX time'''
        try:
            previous = self.my_disker.getPrevious()
        except:
            #-2 is an error code. In case shit goes wrong while accessing the file
            return (-2, 0)
        #return the result and time
        return (previous[0], previous[1])
    def getCurrent(self):
        '''Gets current number of documents and current UNIX time'''
        try:
            current_result = self.my_elasticsearcher.getCurrent(self.index)
        except:
            #-1 is an error code. In case shit goes wrong while interrogating Elasticsearch
            return (-1, 0)
        current_time = timer()
        return (current_result,  current_time)

    def printandexit(self, result):
        '''Given the number of inserts per second,  it gives the formatted text and the exit code'''
        text="Number of documents inserted per second (index: %s) is %f" % (self.index if self.index != '' else 'all',  result)
        if self.threshold == 'lt':
          if result<self.warn:
              return (text, OK)
          if result<self.crit:
              return (text, WARNING)
          else:
              return (text, CRITICAL)
        elif self.threshold == 'gt':
          if result<self.crit:
              return (text, CRITICAL)
          if result<self.warn:
              return (text, WARNING)
          else:
              return (text, OK)
        else:
          return ('Unknown threshold value', UNKNOWN)

    def run(self):
        '''This does everything,  and returns the text to be printed and the exit code'''
        #get the current number of documents and time
        (new_value,  new_time) = self.getCurrent()
        #check if the result is a known error code
        if new_value == -1:
            text = "There was an issue getting the status - and number of docs - from Elasticsearch. Check that ES is running and you have pyes installed"
            return (text, UNKNOWN)
        #get the previous number of documents and time
        (old_value,  old_time) = self.getPrevious()
        #if the new value could be retrieved,  try to write it to a file
        try:
            self.my_disker.writeCurrent(new_value, new_time)
        except:
            #if that failed,  return UNKNOWN
            text = "There was an issue writing the current results to file."
            return (text, UNKNOWN)
        #check if the old value result is a known error code
        if old_value == -2:
            text = "There was an issue getting the previous results from file."
            return (text, UNKNOWN)
        result = self.calculate(old_value, new_value, old_time, new_time)
        (text, exitcode) = self.printandexit(result)
        return (text, exitcode)


def timer():
    '''Interface for time.time(). Good for testing'''
    return time.time()


def opener(file='/tmp/check_es_insert',  mode="r"):
    '''Interface for open(). Good for testing'''
    return open(file, mode)


def printer(text):
    '''interface for print()'''
    print text


def exiter(code):
    '''interface for exit()'''
    exit(code)


class Disker():
    def __init__(self, file='/tmp/check_es_insert'):
        self.file = file
    def getPrevious(self):
        myfile = opener(self.file)
        mydata = myfile.readline()
        numdocs = int(mydata.split(" ")[0])
        time = float(mydata.split(" ")[1])
        return (numdocs, time)
    def writeCurrent(self, value, time):
        myfile = opener(self.file, "w")
        myfile.write("%d %f" % (value, time))


class Elasticsearcher():
    def __init__(self, address='localhost:9200'):
        self.address = address
        self.mysum = 0
    def getCurrent(self,  index=''):
        conn = pyes.ES([self.address])
        status = conn.indices.status()
        for es_index in status['indices'].iterkeys():
            if index == es_index or index == "":
                self.mysum = self.mysum + status['indices'][es_index]['docs']['num_docs']
        return self.mysum


def getArgs(helptext):
    '''Here's where we get our command line arguments'''
    parser = argparse.ArgumentParser(description=helptext)
    parser.add_argument('-c', '--critical',  type=float,  help='Critical value',  action='store', required=True)
    parser.add_argument('-w', '--warning',  type=float,  help='Warning value',  action='store', required=True)
    parser.add_argument('-t', '--threshold',  choices=['lt', 'gt'],  type=str,  help='Check result less than (lt) or greater than (gt) the warning/critcal values',  action='store', default='lt')
    parser.add_argument('-a', '--address',  type=str,  help='Elasticsearch address',  action='store', default='localhost:9200')
    parser.add_argument('-i', '--index',  type=str,  help='Elasticsearch index',  action='store', default='')
    parser.add_argument('-f', '--file',  type=str,  help='Where to store gathered data',  action='store', default='/tmp/check_es_insert')
    return vars(parser.parse_args())

def main():
    '''The main function'''
    cmdline = getArgs('Nagios plugin for checking the number of inserts per second in Elasticsearch')
    if cmdline['file'] == '/tmp/check_es_insert' and cmdline['index'] != '':
          cmdline['file'] = '/tmp/check_es_insert_' + cmdline['index']
    #print cmdline
    #exit()
    my_calculator = Calculator(warn=cmdline['warning'], crit=cmdline['critical'], myfile=cmdline['file'], myaddress=cmdline['address'], threshold=cmdline['threshold'], index=cmdline['index'])
    (text, exitcode) = my_calculator.run()
    printer(text)
    exiter(exitcode)

if __name__ == '__main__':
    main()
