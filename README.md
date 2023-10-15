# Red Hat Service Interconnect Helm Chart

This chart provides an easy and seamless install of Red Hat Service Interconnect (RHSI) on OpenShift. All the options that are available with `skupper init` Command-Line Interface (CLI) command are available in this helm chart too.

## Install the Skupper CLI in your development environment

The skupper command-line tool is the primary entrypoint for installing and configuring the Skupper infrastructure. You need to install the skupper command in each environment you'll manage RHSI from, the same as Helm. It doesn't need to be installed on OpenShift nodes.


### Linux/Mac Install
To install the Skupper CLI under you home directory, run: 
```
curl https://skupper.io/install.sh | sh
``` 
It prompts you to add the command to your path if necessary.

### Windows/Manual Install
See https://skupper.io/install/index.html.


## Deploy Skupper in each OpenShift namespace

Red Hat Service Interconnect is designed for use with multiple namespaces- called sites- typically on different clusters. The skupper CLI uses your kubeconfig and current context to select the namespace where it operates. For more information on kubeconfig files, see [here](https://www.redhat.com/sysadmin/kubeconfig).

This guide assumes you have two sites, which are both OpenShift namespaces, called "east" and "west". The sites can be on different, or the same, OpenShift cluster. **Installation for the first time is a two step process.**
### Prerequisites
Before you deploy RHSI, you need to:
* Have project administrator access to the OpenShift namespaces where you want to install RHSI
* Install Helm and the Skupper (see above) CLI on your development environment
* Fill out the `values.yaml` file as appropriate. For a minimal install, just update `common.ingress.domain`. See [below](#common-parameters) for a reference list of all parameters. **Skupper by default uses self signed certificates to install**, you can change this by setting `selfSignedCerts` to false. Place your certificates under the certs folder.  Refer to certificates section below on how to create them.
### Deploy RHSI Using the helm chart

Install the helm chart using the command below, This will install all the components of skupper like Deployments, Secrets, ConfigMaps etc.

Add the rhsi helm repo.
```
helm repo add rhsi https://rmallam.github.io/RHSI-helm
```

Run install

```
helm install skupper rhsi/skupper
```

**OR**

clone the git repo and navigate into the RHSI-helm folder. Run the following command.
```
helm upgrade --install skupper ./charts/rhsi
``` 

## Status

Check the status of the installation by running following command.

```
skupper status
Skupper is enabled for namespace "skupper-2" in interior mode. It is not connected to any other sites. It has no exposed services.
The site console url is:  https://skupper-skupper-2.apps-crc.testing

```
## Linking to Another RHSI Site

Afer you've successully installed Skupper in both the east and west site, you'll want to link them. We call west a "remote site" from east, and vice versa. Skupper links can originate from any site, and they are bi-directional, so there is **no need to create a link from both sites**.

The linking process will change depending on if you've used the self-signed skupper certificates or your own certifcates.

### Self-Signed Skupper Certificates
Set `linkTokenCreate` to true on **one site** (or one per pair if you have more than two sites). Copy the token generated on that site using the commands specified by the Helm chart output.

This will create a secret called **skupper-link-token** which should be extracted and copied on to the remote site.

```
oc get secret skupper-link-token -o yaml | grep -v creationTimestamp | grep -v namespace | grep -v uid | grep -v resourceVersion | grep -v "kubectl.kubernetes.io/last-applied-configuration"  > connectiontoken.yaml
```

### Custom Certificates

The skupper router exposes a route called 'skupper-inter-router' that will be used to allow incoming links from other skupper sites. You can get the URL by running `oc get route skupper-inter-router -o jsonpath='{.spec.host}` Use the output of this command and update the remotes sites definition for both edgehost and interrouterhost.

For example: 

#### West site
Grab the interrouter host of west namespace 

```
oc get route skupper-inter-router -o jsonpath='{.spec.host}
```

#### East site

In the `values.yaml` file, set the following:

```linkTokenCreate: true
   selfSignedCerts: false
    remoteSites:
    - name: Remote site name for reference
      edgehost: value grabbed from other namespace
      interrouterhost: value grabbed from other namespace
```

Upgrade the Helm chart on the east site:
```
helm upgrade skupper ./ --set siteconfigonly=false -n east-site
``` 

## Moving from another installation of RHSI to this new helm chart

If you already have RHSI installed using another method and want to migrate to this chart, it is a very simple two step process.

1. Run converttohelm.sh script and pass the namespace name as a variable. This will convert all the resources that were created previously to be owned by Helm. Note this script assumes the helm release name is `skupper`.

```
converttohelm.sh test-dev-namespace
```   

2. Install the helm chart to upgrade. Note that if you are using custom certificates, you need to have those certs placed in the certs folder before running this command.

```
helm upgrade --install skupper ./ --set siteconfigonly=false
```

## Certificates
This chart by default generates self signed certificates that are used by skupper router and service controller pods. This is controlled by the variable from the values file called `selfSignedCerts`. This defaults to true.

To use custom certificates, set `selfSignedCerts` to false and place your custom certificates and Certificate Authority (CA) in the certs folder before installing this chart.
The certs folder should contain the following files, with the same naming conventions shown below.

1. `tls.crt`: The certificate that should be used by skupper. This will be used for internal communication between skupper router and service controller and also for inter router communications between skupper routers. The below CN's should be part of the certificate Subject alternative names for the install to work.

    * `skupper-inter-router-${namespace}.${clusterdomain}`: Interrouter route hostname to communicate across the clusters. if a different hostname is chosen, that should be updated in the values.yaml under customhostname so that the route definition has that name and your cert should have it included in the SAN.

    * `skupper-router-local.${namespace}.svc.cluster.local`

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
        
2. `tls.key`: key for the certificate.
3. `ca.crt`: Certificate Authority who signed the certificate.

## List of Valid Parameters for `values.yaml`
### Common parameters

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

### Skupper router parameters

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


### Flow collector parameters

| Name                 | Description                                                                                                    | Value           |
| ------               | -------------------------------------------------------------------------------------------------------------- | --------------- |
| `flowController.enabled`    | Enable flow collector                                                          | `"true/false"`            |
| `flowController.cpu.requests`  | Flow controller cpu requests                                                         | `"50m"`            |
| `flowController.cpu.limits`    | Flow controller cpu Limits                                                          | `"50m"`            |
| `flowController.memory.requests`  | Flow controller memory requests                                                         | `"256Mi"`            |
| `flowController.memory.limits`    | Flow controller memory Limits                                                          | `"256Mi"`            |


## Troubleshooting and Health Check Tips

Status of installation:
```
skupper status 
```
View link status:
```
skupper link status
```
View services exposed:
```
skupper service status
```

If your sites aren't connected, run `skupper debug events` and check the service sync event to see if it the connection was established. The event will look like below.  If the certificates are not correct, you will see an error here about certificates.
```
$ skupper debug events 

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
