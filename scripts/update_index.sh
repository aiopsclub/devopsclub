#!/bin/bash -
#===============================================================================
#
#          FILE: update_index.sh
#
#         USAGE: ./update_index.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 07/12/2020 03:56:28 PM
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error
cd /opt/hugo/content
hugo-algolia -s --config ../config.yaml -i "zh/**"  --output ../public/algolia.json
