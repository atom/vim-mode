_ = require 'underscore-plus'
IndentOperators = require './indent-operators'
Put = require './put-operator'
Input = require './input'
Replace = require './replace-operator'
Operators = require './general-operators'

Operators.Put = Put;
Operators.Replace = Replace;
_.extend(Operators, IndentOperators)

module.exports = Operators
