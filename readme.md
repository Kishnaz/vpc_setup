•	Creating a VPC 
•	Creating the Subnet’s (Public & Private) 
•	Creating NAT & IGW
•	Subnet association - with IGW
•	Subnet association - with NAT 
•	NACL rule setting 
•	SG creation & Port allocation 
•	Creating an EC2 in Public Subnet for Web Server (NGINX)
•	Creating an EC2 in Private Subnet as App Server (Tomcat) 


Please update the nginx file in the location /etc/nginx/nginx.conf

Add the below entry under the location area 

proxy_pass http://#addprivateip:8080;
proxy_set_header X-Real-IP  $remote_addr;

Change the Private IP accordingly


Note : The key name has to be matching with your AWS Account
