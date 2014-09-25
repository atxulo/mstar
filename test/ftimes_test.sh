#!/bin/bash

# Test basico para comprobar que el sistema de test funciona

. test/assert.sh

# Llamada con parametros correctos con la cartera de pruebas - transaccional
assert_raises "./mstar_ftimes.sh -u %usuario% -p %password% 2240736" 0
