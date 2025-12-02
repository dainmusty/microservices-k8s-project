# Helm Installation Guide

## Overview
This project provides a comprehensive guide for installing Helm on Windows. Helm is a powerful package manager for Kubernetes that simplifies the deployment and management of applications on Kubernetes clusters.

## Purpose
The purpose of this project is to offer clear and concise instructions for Windows users to install Helm, ensuring they can easily manage their Kubernetes applications.

## What is Helm?
Helm is a tool that streamlines the process of managing Kubernetes applications. It allows users to define, install, and upgrade even the most complex Kubernetes applications using a simple command-line interface.

## Installation Guide
For detailed step-by-step instructions on installing Helm on Windows, please refer to the following document:

- [Install Helm on Windows](docs/install-helm-windows.md)

## Additional Resources
- [Helm Official Documentation](https://helm.sh/docs/)
- [Kubernetes Official Documentation](https://kubernetes.io/docs/home/)

Feel free to explore the resources provided to enhance your understanding and usage of Helm in your Kubernetes environment.


ArgoCD
for deploying your objects automatically
expose the argocd deployments as an alb
find out what the notifications controller does

after running the command below
echo $ARGO_PWD
 
 copy the output and run


 use ur jenkins server ip with port 9000 to access the sonarcube container; username and password
 admin
 admin

new passwd
 admin1234
 admin1234

 save your sonar token somewhere

 configure webhooks
 go to configuration - webhooks

 use the ip of your jenkis server

 go to projects


 go to jenkins- add crenditials- secret text -sonar-token


tools
 tumerin
 owasp - dependency checker
 docker api, sonarcube scanner

 Docker
Docker Commons
Docker Pipeline
Docker API
docker-build-step
Eclipse Temurin installer
NodeJS
OWASP Dependency-Check
SonarQube Scanner

jdk-17.0.1+12

 this is node js app

add the installed tools to your pip
sonar-scanner
node js 14.00


add dependency check    
DP-Check

add docker
docker select latest

go to sys

sonar cube servers
name - sonar-server
server - jenkins url /9000
server authentication
token

go to argocd - settings - connect tru https - put your git details and connect using your personal access token

once there is a new image push, argo picks up the image and automatically deploys that application