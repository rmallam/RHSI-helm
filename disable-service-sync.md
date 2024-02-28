Skupper by default will syncronsie the service to all the sites that are connected with. But for any security reasons, you dont want this to happen, Skupper provides a option to disable it. 

** Things to consider **
1.  Service sync can be disabled at the time of installation only.
2.  You cant change the mode of sync after install.
3.  Each site can choose either to participate or not individually. it is not all or none.

** How to ** 

at the time of skupper init pass the flag **--enable-service-sync=false** to disable service sync

skupper init --enable-service-sync=false
