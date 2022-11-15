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
- Your lab report is detailed and complete

## 2.1. Set up the monitoring server

Add a new server, called `srv004` to the `vmlab` environment and assign IP-address 172.16.128.4. Install Prometheus using the `cloudalchemy.prometheus` role.

Set the variables `prometheus_targets` and `prometheus_scrape_configs`.

Log in to the Prometheus dashboard and check that you receive metrics from your monitoring server itself.

If your Prometheus server has to access all monitored VMs through their IP-address, the metrics they emit will become harder to interpret. We have set up a DNS server, so let's make use of it. In `site.yml`, add a `pre_task:` to the playbook section for `srv004` where you set your DNS server as the resolver to be used by your monitoring server. Remember that on EL, this is done by editing the `/etc/resolv.conf` file.

From now on, in any Prometheus configuration setting, you can specify any host with their FQDN (e.g. `srv001.infra.lan`) instead of their IP address.

> If the Prometheus installation complains about `libselinux-python` rename `redhat.yml` to `redhat-7.yml` and `redhat-8.yml` to `redhat.yml` in the roles' `vars` folder.

## 2.2. Install Node Exporter

The Prometheus server polls all monitored systems for any metrics that you expose. Basic system metrics can be provided by Prometheus' Node Exporter.

Install the `cloudalchemy.node_exporter` role on all VMs in your setup. Update the `prometheus_targets` and/or `prometheus_scrape_configs` as needed.

Restart Prometheus and ensure that it can access metrics for all the VMs.

## 2.3. Create a Dashboard with Grafana

The Prometheus web UI allows you to enter queries to visualize specific metrics. However, this is quite cumbersome, as it only shows what you ask for. What you probably want is a dashboard that shows essential information about the systems being monitored. Prometheus recommends to use Grafana for this purpose.

Install the `cloudalchemy.grafana` role on your monitoring server. Set up Prometheus as a data source. In the web interface, create a Dashboard that shows at least some metrics gathered from Prometheus.

> If the installation fails due to a failing GPG key check, have a look at the template file for Grafana's yum repository configuration. Try to create your own template which does not check the GPG key for now (have a look in the role documentation how you can change this).
> Related issue: <https://github.com/grafana/grafana/issues/55962>

If an existing Grafana Dashboard can be reused for your setup, this can be automated through one of the role variables. If not, it's okay if the dashboard was created manually and cannot be automatically reproduced after a `vagrant destroy; vagrant up`. In that case, it's important to document the process thoroughly in your lab report.

## 2.4. Extensions

- Make the gathering of metrics more secure with e.g. stricter firewall rules (only the monitoring server can access the Node Exporter port), TLS/SSL, authentication, ...
- Set up instrumentation for Apache, e.g. following [this article](https://computingforgeeks.com/monitor-apache-web-server-prometheus-grafana/). Update your Dashboard to include Apache metrics.
- Similarly, set up instrumentation for [BIND](https://github.com/prometheus-community/bind_exporter) and [MariaDB](https://github.com/prometheus/mysqld_exporter).
