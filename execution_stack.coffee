class ExecutionStack
	constructor: (@obj)->
		@funcs = []
		@args = []

	push: (func, args)->
		@funcs.push func
		@args.push args
		undefined

	exec: ->
		@funcs.pop().apply(@obj, @args)