# Cloud-Resume-Project
This project is an online version of my resume as a static web page, using HTML, CSS, and Javascript.

My domain is available here, the end result of this project.

## How it works:

### On push:

 * Injection of Terraform environmental variables based on deployment location(Dev vs Prod)
  
 * Terraform init
  
 * Terraform apply
  
 * Python Code dependencies are installed via Pip
  
 * Python code zipped
  
 * Python code deployed to storage blob
  
 * Cypress tests are run on website to validate functionality
  
 * On successful Cypress run, Dev workflow ends and Prod workflow begins
  
 * Prod infrastructure hosts the public-facing result of this project
  
  
 ### High-Level Functionality
  
 * Azure storage blob hosts website
  
 * Azure CDN for front end functionality, HTTPS, cert, etc.
  
 * CosmosDB and Python Azure Function for visitor counter
  
 * JS used to call Python API and show visitor counter
 
 ### System Diagram
![System Diagram](https://user-images.githubusercontent.com/48837572/215604709-0072659f-97ba-491a-92ca-94c2ac390311.png)

Most services are provisioned by Terraform Infrastructure as Code.

The Azure Function App Functions are not, due to a known Terraform bug (https://github.com/hashicorp/terraform-provider-azurerm/issues/17943) that I was unable to work around.

I hope to revisit that in the future, as well as other tasks under 'Issues'


