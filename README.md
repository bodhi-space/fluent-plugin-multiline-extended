# Extended Multiline plugin for [Fluentd](http://fluentd.org)

These plugins extend built-in multiline tail parsing to allow for event boundary beyond single line regex matching using the "format_firstline" parameter.  In particular,
+ boundary detection can be done using regex matches at either the beginning or the end of the event, and
+ boundary detection regexes to span more than one line.

## Overview
The plugins provided subclass the [tail plugin](http://docs.fluentd.org/categories/in_tail) and [parser](http://docs.fluentd.org/articles/parser-plugin-overview) in order to extend event boundary detection functionality.   The original use case for creating this extension was in an attempt to deal with RabbitMQ logs in a coherent way, since they require a multiline regex in order to properly and consistently determine log event boundaries (without throwing errors during normal operation, at least) since information from two lines is required.   Other used have since cropped up where this functionality is needed (for example, logs which do not always terminate entries with a newlines).

RabbitMQ "INFO REPORT" messages normally look like this.

```

=INFO REPORT==== 1-Nov-2016::23:25:39 ===
FHC read buffering:  OFF
FHC write buffering: ON
```

Note that the blank line is at the _beginning_ of the event, not the end.  The only way to correctly specify the format_firstline for the multiline plugin so that it will not continually throw timeout errors is to set it to match a blank line.  This would not be a problem if RabbitMQ did not ocassionally generate garbage like the following.

```

=INFO REPORT==== 1-Nov-2016::23:26:09 ===
Timeout contacting cluster nodes: ['rabbit@host-a',
                                   'rabbit@host-b','rabbit@host-c',
                                   'rabbit@host-d',
                                   'rabbit@host-e'].

BACKGROUND
==========

This cluster node was shut down while other nodes were still running.
To avoid losing data, you should start the other nodes first, then
start this one. To force this node to start, first invoke
"rabbitmqctl force_boot". If you do so, any changes made on other
cluster nodes after this one was shut down may be lost.

DIAGNOSTICS
===========

attempted to contact: ['rabbit@host-a','rabbit@host-b',
                       'rabbit@host-c','rabbit@host-d',
                       'rabbit@host-e']

rabbit@host-a:
  * unable to connect to epmd (port 4369) on host-a: nxdomain (non-existing domain)

rabbit@host-b:
  * connected to epmd (port 4369) on host-b
  * node rabbit@host-b up, 'rabbit' application not running
  * running applications on rabbit@host-b: [ssl,public_key,crypto,xmerl,
                                                syntax_tools,inets,asn1,
                                                compiler,ranch,sasl,stdlib,
                                                kernel]
  * suggestion: start_app on rabbit@host-b
rabbit@host-c:
  * connected to epmd (port 4369) on host-c
  * node rabbit@host-c up, 'rabbit' application not running
  * running applications on rabbit@host-c: [ssl,syntax_tools,public_key,
                                                asn1,compiler,ranch,xmerl,
                                                inets,crypto,sasl,stdlib,
                                                kernel]
  * suggestion: start_app on rabbit@host-c
rabbit@host-d:
  * unable to connect to epmd (port 4369) on host-d: nxdomain (non-existing domain)

rabbit@host-e:
  * unable to connect to epmd (port 4369) on host-e: nxdomain (non-existing domain)


current node details:
- node name: 'rabbit@host-a'
- home dir: /var/lib/rabbitmq
- cookie hash: XXXXXXXXXXXXXXXXXXXXXX==
```

There is no way to configure the multiline plugin format_firstline so that it will treat the following RabbitMQ as a single log event without throwing parsing errors during normal operattion: specifying a blank line will not work due to newlines embedded in records and Specifying "^=[A-Z]" will not work (at least, not without continually generating timeout errors, since this matches the _second_ line of the event record, not the first).  The ability to specify the multiline regex "\n=[A-Z]" is actually required to parse these logs without generating parsing errors during normal operation.

## Installation

Use ruby gem as :

    gem 'fluent-plugin-multiline-extended'

Or, if you're using td-client, you can call td-client's gem command

    /opt/td-agent/embedded/bin/gem install fluent-plugin-multiline-extended

## Configuration

```
<source>
  path <filename>
  type tail_multiline_extended
  format multiline_extended
  splitter_matches (head or tail -- defaults to head)
  splitter_regex (regex for splitting events which can contain newlines)
  [ additional tail or format parameters ]
</source>
```

## Examples

### RabbitMQ input parser that correctly detects event boundaries
```
<source>
  type tail_multiline_extended
  format multiline_extended
  splitter_matches head
  splitter_regex /\n=[A-Z]+ REPORT=/
  format1 /^\s*(?<full_message>=(?<report_type>\S+)\s+REPORT====\s*(?<time>\S+) ===[\*\s]*(?<message>[^\n]*[^\*\s]).*)[\*\s]*$/
  time_format %e-%b-%Y::%H:%M:%S
  multiline_flush_interval 5s
  path /var/log/rabbitmq/*.log
  pos_file /var/lib/td-agent/rabbitmq.pos
  tag *.rabbitmq.RABBITMQ
</source>
```

