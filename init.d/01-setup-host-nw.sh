#!/bin/bash

ip l add v-qb type veth peer eth0 netns qb
ip l set v-qb up
ip -n qb l set eth0 up

ip a add 10.169.254.2/30 dev v-qb
ip -n qb a add 10.169.254.1/30 dev eth0
