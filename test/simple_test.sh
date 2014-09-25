#!/bin/bash

# Test basico para comprobar que el sistema de test funciona
. test/assert.sh

assert "echo OK" "OK"
