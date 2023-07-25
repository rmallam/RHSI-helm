# How to use this helm chart

This chart will provide an ability to deploy Red Hat Service interconnect in a easy and seamless manner. All the options that are available with Skupper cli init are available in this helm chart too.

## Basic Install

Installation for the first time is a two step process.

1. Install Skupper-site configmap

``` helm upgrade --install skupper ./ --set siteconfigonly=true``` 
       

2. Deploy other components of skupper.

``` helm upgrade --install skupper ./ --set siteconfigonly=false``` 



## Moving from anyother installation of RHSI to this new helm chart

if you already have RHSI installed using anyother method and want to migrate to this chart, it is a very simple two step process.

1. Run convert2helm.sh script by passing the namespace name as a variable. This will convert all the resources that were created previously to be owned by Helm. this script will assume the helm release name to be skupper.

``` converttohelm.sh test-dev-namespace```   

2. We have now converted all the components to be owned by helm. We can now use the helm chart to upgrade .

  ```helm upgrade --install skupper ./ --set siteconfigonly=false```


### Common parameters

| Name                 | Description                                                                                                    | Value           |
| ------               | -------------------------------------------------------------------------------------------------------------- | --------------- |
| `siteconfigonly`     | Deploy only site config map and not the other resources                               | `""`            |
| `console.enabled`    | Enable skupper console                                                                | `""`            |

### skupper Router parameters

| Name                 | Description                                                                                                    | Value           |
| ------               | -------------------------------------------------------------------------------------------------------------- | --------------- |
| `router.cpu.requests`  | router cpu requests                                                         | `"50m"`            |
| `router.cpu.limits`    | router cpu Limits                                                          | `"50m"`            |
| `router.memory.requests`  | router memory requests                                                         | `"256Mi"`            |
| `router.memory.limits`    | router memory Limits                                                          | `"256Mi"`            |
| `router.ingressHost`    | Ingress domain for the cluster, defaults to cluster domain if not provided                                                      | `"apps.route.test"`            |
| `router.ingressType`    | Ingress type                                                         | `"route/ingress"`            |
| `router.mode`    | Mode on which router should run                                                  | `"interior/edge"`            |
| `router.replicas`    | number of replicas routers should run                                          | `"1"`       |
| `router.annotations`    | annotations that should be created on router pod                                        | `""`       |
| `router.labels`    | labels that should be created on router pod                                        | `""`       |


### Service controller parameters

| Name                 | Description                                                                                                    | Value           |
| ------               | -------------------------------------------------------------------------------------------------------------- | --------------- |
| `serviceController.enabled`    | Enable service controller                                                        | `"true/false"`            |
| `serviceController.disableServiceSync`   | disbale service sync from other cluster - default false                                   | `"true/false"`            |
| `serviceController.cpu.requests`  | Enable service controller cpu requests                                            | `"50m"`            |
| `serviceController.cpu.limits`    | Enable service controller cpu limits                                                           | `"50m"`            |
| `serviceController.memory.requests`  | Enable service controller memory requests                                                        | `"256Mi"`            |
| `serviceController.memory.limits`    | Enable service controller memory limits                                                        | `"256Mi"`       


### flow collector parameters

| Name                 | Description                                                                                                    | Value           |
| ------               | -------------------------------------------------------------------------------------------------------------- | --------------- |
| `flowController.enabled`    | Enable flow collector                                                          | `"true/false"`            |
| `flowController.cpu.requests`  | Flow controller cpu requests                                                         | `"50m"`            |
| `flowController.cpu.limits`    | Flow controller cpu Limits                                                          | `"50m"`            |
| `flowController.memory.requests`  | Flow controller memory requests                                                         | `"256Mi"`            |
| `flowController.memory.limits`    | Flow controller memory Limits                                                          | `"256Mi"`            |


### Health Check:

Status of installation.

    *   skupper status 

View link status

    * skupper link status

View services exposed

    * skupper service status

Skupper cli can be downloaded here https://skupper.io/releases/index.html

https://confluence.service.anz/display/CAP/Health+Check+Guide

run skupper debug events and check the service sync event if it was established. the event will look like below.  If the certs are not correct, you will see an error here about certificates.


View skupper events
 
    *   skupper debug events
``` 

ServiceSyncEvent             4                                                                                     2m25s
                             1     Service interface(s) modified web                                               2m25s
                             1     Service sync sender connection to                                               2m28s
                                   amqps://skupper-router-local.mas-dev-di1001.svc.cluster.local:5671
                                   established
                             1     Service sync receiver connection to                                             2m28s
                                   amqps://skupper-router-local.mas-dev-di1001.svc.cluster.local:5671
                                   established
                             1     Service interface(s) added backend,web   
                             
  ```
