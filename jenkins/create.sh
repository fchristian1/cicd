#!/bin/bash
cd terraform &&
    terraform init &&
    terraform apply -auto-approve &&
    cp ../inventory ../ansible/inventory &&
    cp my_key.pem ../my_key.pem
