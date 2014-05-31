_ = require 'underscore-plus'
IndentOperators = require './indent-operators'
Put = require './put-operator'
InputOperators = require './input'
Replace = require './replace-operator'
Operators = require './general-operators'

Operators.Put = Put;
Operators.Replace = Replace;
_.extend(Operators, IndentOperators)
_.extend(Operators, InputOperators)
module.exports = Operators
