#!/bin/bash
case "$1" in
    pre) modprobe -r iwlmvm iwlwifi ;;
    post) modprobe iwlwifi ;;
esac
