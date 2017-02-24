# Kibana Puppet Module

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with Kibana](#setup)
    * [What Kibana affects](#what-kibana-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with Kibana](#beginning-with-kibana)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module manages Kibana for use with Elasticsearch.

## Module Description

In addition to managing the Kibana system package and service, this module also
exposes options to control the configuration file for Kibana.

Dependencies are fairly standard (stdlib and apt for Debian-based
distributions).

## Setup

### What Kibana affects

* The `kibana` system package
* `/etc/kibana`

### Setup Requirements **OPTIONAL**

In addition to basic puppet settings (such as pluginsync), ensure that the
required dependencies for the module are met (these are listed in
`metadata.json` and listed in the Puppet Forge). 

### Beginning with kibana

Quick start:

```puppet
class { 'kibana' : }
```

## Usage

In order to control Kibana's configuration file, use the `config` parameter:

```puppet
class { 'kibana':
  config => {
    'server.port' => '8080',
  }
}
```

## Reference

Here, list the classes, types, providers, facts, etc contained in your module. This section should include all of the under-the-hood workings of your module so people know what the module is touching on their system but don't need to mess with things. (We are working on automating this section!)

## Limitations

This module is actively tested against the versions and distributions listed in
`metadata.json`.

## Development

See CONTRIBUTING.md with help to get started.
