# Sensu Plugins Habitat

[![Build Status](https://img.shields.io/travis/com/socrata-platform/sensu-plugins-habitat.svg)][travis]
[![Gem Version](https://img.shields.io/gem/v/sensu-plugins-habitat.svg)][rubygems]

[travis]: https://travis-ci.com/socrata-platform/sensu-plugins-habitat
[rubygems]: https://rubygems.org/gems/sensu-plugins-habitat

A set of Sensu plugins for monitoring Habitat.

## Functionality

This gem includes a plugin for monitoring Habitat services' health check statuses via a supervisor API.

## Files

* bin/check-habitat-service-health.rb

## Usage

***check-habitat-service-health.rb***

With only default options, the `check-habitat-service-health.rb` script assumes a Habitat supervisor on `127.0.0.1:9631`, iterates over all services running under that supervisor, and aggregates their health check statuses. The final overall status of the check is whatever the most serious status is of any one service, e.g. if 4/5 services are OK and one is in WARNING, the check result will be a WARNING.

```shell
check-habitat-service-health.rb
```

If the Habitat supervisor is on another host:

```shell
> check-habitat-service-health.rb -H 192.168.0.4
> check-habitat-service-health.rb --host 192.168.0.4
```

If the Habitat supervisor is on another port:

```shell
> check-habitat-service-health.rb -P 4242
> check-habitat-service-health.rb --port 4242
```

To check only a particular set of services running under the Habitat supervisor:

```shell
> check-habitat-service-health.rb -s service1.default,service2.default
> check-habitat-service-health.rb --services service1.default,service2.default
```

In this case, any service that is specified and not running will be counted as a CRITICAL.

## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)
