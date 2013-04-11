console.log 'Converting styles.txt to styles.coffee'

fs = require 'fs'
arr = fs.readFileSync('styles.txt').toString().split('\n')

out = "module.exports =\n"
for style in arr
  stle = style.replace ' ', ''
  out += "  '#{style}': {tag: ''} \n"

fs.writeFileSync 'styles.coffee', out

console.log """Generated styles.coffee. To use: require 'style.coffee'"""
