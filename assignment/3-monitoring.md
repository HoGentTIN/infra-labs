# Lab 3: Monitoring

In this assignment, you will set up a server that allows you to monitor the entire virtual environment set up in the configuration management lab.

## Learning goals

- Installing Prometheus and Node Exporter
- Configure basic system monitoring (CPU, memory, etc.)
- Monitor services
- Setting up a monitoring dashboard with Grafana

## Acceptance criteria

- Demonstrate the working Prometheus server:
    - Show targets in the webinterface
    - Run a query for a metric
- Show the Grafana dashboard you created
- Demonstrate any extensions to the assignment that you have implemented

## 2.1. Set up the server

Add a new server, called `srv004` to the `vmlab` environment. Install Prometheus using the `cloudalchemy.prometheus` role. All VMs (including `srv004`) should also have the `cloudalchemy.node_exporter` role installed.

Set the variables `prometheus_targets` and `prometheus_scrape_configs`.

Log in to the Prometheus dashboard and check that you receive metrics from all targets.

## 2.2. Install Node Exporter

The Prometheus server polls all monitored systems for any metrics that you expose. Basic system metrics can be provided by Prometheus' Node Exporter.

Install the `cloudalchemy.node_exporter` role on all VMs in your setup. Update the `prometheus_targets` and/or `prometheus_scrape_configs` as needed.

Restart Prometheus and ensure that it can access metrics for all the VMs.

## 2.3. Create a Dashboard with Grafana

The Prometheus web UI allows you to enter queries to visualize specific metrics. However, this is quite cumbersome, as it only shows what you ask for. What you probably want is a dashboard that shows essential information about the systems being monitored. Prometheus recommends to use Grafana for this purpose.

Install the `cloudalchemy.grafana` role on your monitoring server. Set up Prometheus as a data source. In the web interface, create a Dashboard that shows at least some metrics gathered from Prometheus.

## 2.4. Extensions

- Make the gathering of metrics more secure with e.g. stricter firewall rules (only the monitoring server can access the Node Exporter port), TLS/SSL, authentication, ...
- Set up instrumentation for Apache, e.g. following [this article](https://computingforgeeks.com/monitor-apache-web-server-prometheus-grafana/). Update your Dashboard to include Apache metrics.
- Similarly, set up instrumentation for [BIND](https://github.com/prometheus-community/bind_exporter) and [MariaDB](https://github.com/prometheus/mysqld_exporter).
