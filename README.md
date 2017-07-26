# Get-DellWarrantyInfo
A script for utilizing the Dell Warranty Management API

## Background Information
My employer was looking for a way to get the age and warranty information of the computers we have purchased from dell without having to go to the warranty website and enter hundreds of service tags and countless CAPTCHAS by hand. Luckily dell offers this service. Al lyou have to do is set up an account on TechDirect under your company and request a Dell Warranty Management API key and follow their processes. Hopefully this script helps someone else out there, either to just do the job - or to offer a decent starting point for further work.

## Notes
For my organization, we had just under 500 Dell computers of interest. Running the script with the request limiter of 5 seconds took ~40 minutes to complete for that volume. Go grab a coffee and chat with the receptionist.
