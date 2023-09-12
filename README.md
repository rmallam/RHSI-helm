# How to use this Helm chart

This chart will provide an ability to deploy Red Hat Service Interconnect (RHSI) in a easy and seamless manner. All the options that are available with Skupper CLI init are available in this helm chart too.

## Step 1: Install the Skupper command-line tool in your environment

The skupper command-line tool is the primary entrypoint for installing and configuring the Skupper infrastructure. You need to install the skupper command only once for each development environment.

Use the install script to download and extract the command:

### LINUX OR MAC
curl https://skupper.io/install.sh | sh
The script installs the command under your home directory. It prompts you to add the command to your path if necessary.

For Windows and other installation options, see https://skupper.io/install/index.html.


## Step 2: Install the Skupper in each namespace

Red Hat Service Interconnect is designed for use with multiple namespaces, typically on different clusters. The skupper command uses your kubeconfig and current context to select the namespace where it operates.

each namespace where skupper is installed is referred to as a site.

Your kubeconfig is stored in a file in your home directory. The skupper and kubectl commands use the KUBECONFIG environment variable to locate it.

### Installation for the first time is a two step process.

These two steps should be repeated in all the namespaces(assuming east and west are the namespaces) where skupper should be installed.

#### Run these commands on West and East Namespace

1. Install Skupper-site configmap
 
This will install only a configmap called `skupper-site`. This will hold the information about the skupper site like its name and few other details.

``` helm upgrade --install skupper ./ --set common.siteconfigonly=true``` 
       
2. Deploy other components of skupper. 

Note: Skupper by default uses self signed certificates to install, Check the values files and make sure selfsigned certificates variable is set to false and the anz certificates generated are placed under the certs folder.  Refer to certificates section below on how to create them.

``` helm upgrade --install skupper ./ --set siteconfigonly=false``` 

check the status of the installation by running ```skupper status``` command.

Refer to https://confluence.service.anz/display/CAP/Health+Check+Guide for more information on how to perform a health check.

### Linking to Another RHSI Site

We have successully installed skupper in two different namepsaces. This section details on how to link the skupper routers running in these two namespaces/clusters.

*Note: only links using a custom (i.e. not self-signed) CA is covered here. Self-signed token creation is incomplete, and was abandoned as it did not have much application at ANZ.*

Skupper links can originate from any one site(cluster) and the link works bi-directional, so there is NO NEED to create a link from both sites.


#### What are remote sites?
The other cluster/namespaces where skupper is installed is called a Remote site. 
Assuming East namespace as a local skupper site and you want to link it to west namespace, West becomes the remote site of east and Vice-versa

#### what is edgehost and interrouterhost?

Skupper router exposes a route called 'skupper-inter-router' which will be used to allow incoming links from other skupper sites. you can get these URL by running `oc get route skupper-inter-router -o jsonpath='{.spec.host}`

Use the output of this command and update the remotes sites definition for both edgehost and interrouterhost.

For example: 

#### on west namespace
Grab the interrouter host of west namespace 

`oc get route skupper-inter-router -o jsonpath='{.spec.host}`

#### on east namespace

1. In the values file, set the following.

```linkTokenCreate: true
   selfSignedCerts: false
    remoteSites:
    - name: Remote site name for reference
      edgehost: value grabbed from other namespace
      interrouterhost: value grabbed from other namespace
```

2. Upgrade the Helm chart in the site  - i.e. run
``` helm upgrade skupper ./ --set siteconfigonly=false``` 

## Moving from another installation of RHSI to this new helm chart

if you already have RHSI installed using anyother method and want to migrate to this chart, it is a very simple two step process.

1. Run converttohelm.sh script by passing the namespace name as a variable. This will convert all the resources that were created previously to be owned by Helm. this script will assume the helm release name to be skupper.

``` converttohelm.sh test-dev-namespace```   

2. We have now converted all the components to be owned by helm. We can now use the helm chart to upgrade.

Note: if you are using custom certs like ANZ CA, make sure you have those certs placed in the certs folder before running this command.

  ```helm upgrade --install skupper ./ --set siteconfigonly=false```

## Certificates
This chart by default generates self signed certificates which are used by skupper router and service controller pods. This is controlled by the varialbe from the values file called ```selfSignedCerts```. This defaults to true.

To use any custom CA certificates, set the varibale ```selfSignedCerts``` to false in the values.yaml file and place your custom certificates along with the ca in the certs folder before installing this chart.
The certs folder should contain the following files with the same naming conventions shown below

1. tls.crt : The certificate that should be used by skupper. This will be used for internal communication between skupper router and service controller and also for inter router communications between skupper routers. The below CN's should be part of the certificate Subject alternative names for the install to work.

        skupper-inter-router-${namespace}.${clusterdomain}  - Interrouter route hostname to communicate across the clusters. if a different hostname is chosen, that should be updated in the values.yaml under customhostname so that the route definition has that name and your cert should have it included in the SAN.
        skupper-router-local.${namespace}.svc.cluster.local

Note: If you want to use the same certificate across multiple installations of skupper in different clusters. Just add the CN's of the other clusters in the same certificate. you can use the below template to generate the certificate.

        ```
            [req]
            default_bits = 2048
            prompt = no
            default_md = sha256
            req_extensions = req_ext
            distinguished_name = dn

            [ dn ]
            C=AU
            ST=Victoria
            L=Melbourne
            O=Red Hat
            OU=skupper
            CN=skupper-inter-router-access.apps-redhat.com

            [ req_ext ]
            subjectAltName = @alt_names

            [ alt_names ]
            DNS.1 = skupper-inter-router-${namespace1}.${subdomain}
            DNS.2 = skupper-router-local.${namespace1}.svc.cluster.local
            DNS.3 = skupper-router.{namespace1}.svc.cluster.local
            DNS.4 = skupper-inter-router-${namespace2}.${subdomain}
            DNS.5 = skupper-router-local.${namespace2}.svc.cluster.local
            DNS.6 = skupper-router.{namespace2}.svc.cluster.local
        ```
        
2. tls.key : key for the certificate
3. ca.crt : Certificate authority who signed this certificate.


## Common parameters

| Name                 | Description                                                                                                    | Value           |
| ------               | -------------------------------------------------------------------------------------------------------------- | --------------- |
| `common.siteconfigonly`     | Deploy only site config map and not the other resources                               | `""`            |
| `common.customhostname`    | Boolean that enables/disables custom route name for RHSI interrouter                              | `"true/false"`           |
| `common.ingressType`    | Ingress type                                                         | `"route"`            |
| `common.ingress.host`    | Ingress host, set to default host name if not using a custom host                  | `""skupper-inter-router""`          |
| `common.ingress.domain`    |Ingress domain for the cluster, set to default cluster domain if not using a custom domain             | `"apps.route.test"`    |  
| `console.enabled`    | Enable skupper console                                                                | `""`            |
| `selfSignedCerts`    | self signed certs are generated at run time defaults to true                                                        | `"true/false"`            |
| `linkTokenCreate`    | Creates a token that can used to establish a link with remote sites defaults to true                              | `""`            |

### skupper Router parameters

| Name                 | Description                                                                                                    | Value           |
| ------               | -------------------------------------------------------------------------------------------------------------- | --------------- |
| `router.cpu.requests`  | router cpu requests                                                         | `"50m"`            |
| `router.cpu.limits`    | router cpu Limits                                                          | `"50m"`            |
| `router.memory.requests`  | router memory requests                                                         | `"256Mi"`            |
| `router.memory.limits`    | router memory Limits                                                          | `"256Mi"`            |
| `router.mode`    | Mode on which router should run                                                  | `"interior/edge"`            |
| `router.replicas`    | number of replicas routers should run                                          | `"1"`       |
| `router.annotations`    | annotations that should be created on router pod                                        | `""`       |
| `router.labels`    | labels that should be created on router pod                                        | `""`       |


### Service controller parameters

| Name                 | Description                                                                                                    | Value           |
| ------               | -------------------------------------------------------------------------------------------------------------- | --------------- |
| `serviceController.enabled`    | Enable service controller                                                        | `"true/false"`            |
| `serviceController.disableServiceSync`   | Enable service sync from other cluster                                        | `"true/false"`            |
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


## Health Check:

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
                                   amqps://skupper-router-local.ns1.svc.cluster.local:5671
                                   established
                             1     Service sync receiver connection to                                             2m28s
                                   amqps://skupper-router-local.ns1.svc.cluster.local:5671
                                   established
                             1     Service interface(s) added backend,web   
                             
  ```
