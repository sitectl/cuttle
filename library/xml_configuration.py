#!/usr/bin/python

DOCUMENTATION = '''
---
module: xml_configuration
version_added: 0.1
short_description: sets values in xml files
description:
    - Given an xml file, an xpath selector, and a value, this will set the value in the file.
options:
  file:
    description:
      - path of the xml file to work with
    required: true
  xpath:
    description:
      - xpath of the element to set, must match a single element
    required: true
  value:
    description:
      - the value to set
    required: true
'''

EXAMPLES = '''
# sets the first widget to 1 inside the widgets element
- xml_configuration: xpath=/widgets/widget[1] value=1
'''

import xml.etree.ElementTree as ET

def main():
    conf = AnsibleModule(
        argument_spec = dict(
            file  = dict(required=True),
            xpath = dict(required=True),
            value = dict(required=True),
        ),
        supports_check_mode=True
    )

    doc = ET.parse(conf.params['file'])
    changed = False
    report = ''
    elements = doc.findall(conf.params['xpath'])

    # because we create elements if they are not found, we
    # must only match 1 or 0
    assert len(elements) < 2

    val = str(conf.params['value'])

    if len(elements) == 1:
        element = elements[0]
        current_value = element.text

        # normalise None into empty string for easy value testing
        if current_value is None:
            current_value = ''

        if current_value != val:
            changed = True
            old = current_value
            element.text = val
            report = '%s set to %s, was %s' % (conf.params['xpath'], val, old)
    else:
        current_element = doc.getroot()
        path = conf.params['xpath'].split('/')[1:]
        for segment in path:
            next = current_element.findall(segment)
            if not next:
                segment = segment.split('[')[0] # get rid of index matcher
                # create the element, set it as current element
                current_element = ET.SubElement(current_element, segment)
            else:
                current_element = next[0]
        current_element.text = val
        changed = True
        report = '%s added and set to %s' % (conf.params['xpath'], val)

    if changed and not conf.check_mode:
        doc.write(conf.params['file'], encoding='UTF-8', xml_declaration=True)

    conf.exit_json(changed=changed, result=report)



# import site snippets
from ansible.module_utils.basic import *
main()
