@echo off
REM
REM This script generates a "Newt Machine" using Multipass.
REM
echo Launching newt_machine
multipass launch --name newt-machine --memory 4G --disk 150G --cpus 2 --cloud-init newt-init.yaml
multipass info newt-machine
@echo on
