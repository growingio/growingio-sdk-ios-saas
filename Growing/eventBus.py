#!/usr/bin/python
import os
import re
import json

key = 'subscribe'
gio_dir = os.path.abspath(os.path.join(os.getcwd()))
gio_eventbus_dir = gio_dir + '/GrowingCoreKit/GrowingCoreKit/EventBus/MethodMap/GrowingEventBusMethodMap.m'

methodDict = {}

#find .m
def readDir(dir):
    for filename in os.listdir(dir):
        fp = os.path.join(dir, filename)
        if os.path.isfile(fp) and filename.endswith('.m'):
            regularMatch(fp)
        elif os.path.isdir(fp):
            readDir(fp)


# regular match
def regularMatch(dir):
    global key
    global methodDict

    with open(dir, 'r') as f:
        data = f.read()

    # if key not contain of data,return 
    # improve efficiency
    if data.find(key) == -1:
        return

    matchMethods = re.findall(r'\ssubscribe\s+([\+|\-].*?)\{', data, re.S)
    if matchMethods:
        for methodStr in matchMethods:
            pat = '@implementation\s+([a-zA-Z0-9_]+)(.*?)@end'
            matchClasses = re.findall(pat, data, re.S)
            
            expMethodStr = methodStr
            # replace special characters, make regular match work
            expMethodStr =  expMethodStr.replace('(','\(')
            expMethodStr = expMethodStr.replace(')','\)')
            expMethodStr = expMethodStr.replace('+','\+')
            expMethodStr = expMethodStr.replace('-','\-')
            expMethodStr = expMethodStr.replace('*','\*')
            
            endMethodStr = methodStr
            # methodStr format -> endMethodStr
            # use to get value
            endMethodStr = endMethodStr.strip()
            endMethodStr = endMethodStr.replace(' ','')
            endMethodStr = endMethodStr.replace('\n','')
            
            if matchClasses:
                for aclass in matchClasses:
                     contentString = aclass[1];
                     
                     result = re.findall('\ssubscribe\s+' + expMethodStr, contentString, re.S)
                     if len(result) == 0:
                        continue
                     
                     className = aclass[0]
                     isClassMethod = '1' if methodStr.find('+') == 0 else '0'
                     
                     
                     matchSel = re.search(r'\)(.*?)\(', endMethodStr)
                     methodSel = matchSel.group(1)
                     matchEvent = re.search(r':\((.*?)\*\)', endMethodStr)
                     eventStr = matchEvent.group(1)

                     # handle json
                     handleJson(eventStr, className, isClassMethod, methodSel)
    
    else:
        return

def handleJson(eventName, className, methodType, method):
    global methodDict
    arrStr = className + '/' + methodType + '/' + method

    if eventName in methodDict:
        arr = methodDict[eventName]
        if arrStr in arr:
            return
        else:
            arr.append(arrStr)
    else:
        methodDict[eventName] = [arrStr]


def saveDict():
    global methodDict

    methodDictStr = json.dumps(methodDict)
    ocDict = methodDictStr

    ocDict = ocDict.replace('{', '@{')
    ocDict = ocDict.replace('[', '@[')

    str1Arr = []

    pat = '("[a-zA-Z0-9_]+)'
    matches = re.findall(pat, ocDict, re.S)
    if matches:
        for str1 in matches:
            if str1 in str1Arr:
                pass
            else:
                if len(str1Arr) == 0:
                    str1Arr.append(str1)
                else:
                   lastStr = str1Arr[-1]
                   if lastStr.startswith(str1):
                       str1Arr.remove(lastStr)
                       str1Arr.append(str1)
                   elif str1.startswith(lastStr):
                       pass
                   else:
                       str1Arr.append(str1)
                
    for str1 in str1Arr:
        ocDict = ocDict.replace(str1,'@'+str1)

    ocDict = '#import "GrowingEventBusMethodMap.h"\n\n' + '@implementation GrowingEventBusMethodMap\n' + '+ (NSDictionary *)methodMap\n' + '{\n' + '\n   return {ocDict};\n'.format(ocDict=ocDict) + '}\n' + '\n@end'
    with open (gio_eventbus_dir, 'w') as f:
        f.write(ocDict)

    # print methodDict
    # print ocDict
    

readDir(gio_dir)
saveDict()



 
