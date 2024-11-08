import app_root
from src import ast_transformer as transformer

class AdvancedTransformer:

    def create_withdraw_func(self, owner_name, func_name):
        try:
            withdraw = transformer.createNode("FunctionDefinition")
            transformer.setProperty(withdraw, ["name", "visibility", "modifiers", "isConstructor", "stateMutability", "returnParameters"],
                                    [func_name, "public", [], False, None, None])

            withdraw_parameter_list = transformer.createNode("ParameterList")
            withdraw_parameter = transformer.createNode("Parameter")
            uint = transformer.createNode("ElementaryTypeName")
            transformer.setProperty(uint, ["name"], ["uint"])
            transformer.setProperty(withdraw_parameter, ["typeName", "name", "storageLocation", "isStateVar", "isIndexed"],
                                    [uint, "val", None, False, False])
            withdraw_parameters = [withdraw_parameter]
            transformer.setProperty(withdraw_parameter_list, ["parameters"], [withdraw_parameters])
            transformer.setProperty(withdraw, ["parameters"], [withdraw_parameter_list])

            require_func = transformer.createNode("FunctionCall")
            require_param = transformer.createNode("BinaryOperation")

            owner_judge = transformer.createNode("BinaryOperation")
            msg_sender = self.create_msg_sender()
            owner = transformer.createNode("Identifier")
            transformer.setProperty(owner, ["name"], [owner_name])
            transformer.setProperty(owner_judge, ["left", "operator", "right"], [msg_sender, "==", owner])
            transformer.setProperty(require_param, ["left", "operator"], [owner_judge, "&&"])

            val_judge = transformer.createNode("BinaryOperation")
            val = transformer.createNode("Identifier")
            transformer.setProperty(val, ["name"], ["val"])
            balance = transformer.createNode("MemberAccess")
            transformer.setProperty(balance, ["memberName"], ["balance"])
            address_call = self.create_address_call("this")
            transformer.setProperty(balance, ["expression"], [address_call])
            transformer.setProperty(val_judge, ["left", "operator", "right"], [val, "<=", balance])

            require_expr = transformer.createNode("Identifier")
            transformer.setProperty(require_expr, ["name"], ["require"])
            transformer.setProperty(require_param, ["right"], [val_judge])
            transformer.setProperty(require_func, ["names", "expression", "arguments"], [[], require_expr, [require_param]])

            transfer = self.create_transfer_func("msg.sender", "val")

            withdraw_body = transformer.createNode("Block")
            require_func_statement = transformer.createNode("ExpressionStatement")
            transformer.setProperty(require_func_statement, ["statement"], [require_func])
            transfer_statement = transformer.createNode("ExpressionStatement")
            transformer.setProperty(transfer_statement, ["statement"], [transfer])
            transformer.setProperty(withdraw_body, ["statements"], [[require_func_statement, transfer_statement]])
            transformer.setProperty(withdraw, ["body"], [withdraw_body])

            return withdraw
        except Exception as err:
            print("Unable to create a withdraw function node\n", err)

    def create_transfer_func(self, sender, value):
        msg_sender = self.create_member_access("sender", sender)
        val = transformer.createNode("Identifier")
        transformer.setProperty(val, ["name"], [value])
        transfer = transformer.createNode("FunctionCall")
        transformer.setProperty(transfer, ["expression", "arguments"], [msg_sender, [val]])
        return transfer

    def create_msg_sender(self):
        msg_sender = transformer.createNode("MemberAccess")
        msg = transformer.createNode("Identifier")
        transformer.setProperty(msg, ["name"], ["msg"])
        transformer.setProperty(msg_sender, ["memberName", "expression"], ["sender", msg])
        return msg_sender

    def create_address_call(self, address_name):
        address_expr = transformer.createNode("ElementaryTypeNameExpression")
        address_type = transformer.createNode("ElementaryTypeName")
        transformer.setProperty(address_type, ["name"], ["address"])
        transformer.setProperty(address_expr, ["typeName"], [address_type])
        address_call = transformer.createNode("FunctionCall")
        transformer.setProperty(address_call, ["expression", "arguments"], [address_expr, [self.create_identifier(address_name)]])
        return address_call

    def create_identifier(self, name):
        identifier = transformer.createNode("Identifier")
        transformer.setProperty(identifier, ["name"], [name])
        return identifier

    def create_member_access(self, member_name, expression_name):
        member_access = transformer.createNode("MemberAccess")
        expression = self.create_identifier(expression_name)
        transformer.setProperty(member_access, ["expression", "memberName"], [expression, member_name])
        return member_access

    def add_check(self, node):
        try:
            require_expression = transformer.createNode("ExpressionStatement")
            require_func = transformer.createNode("FunctionCall")
            require_id = self.create_identifier("require")
            transformer.setProperty(require_func, ["names", "expression", "arguments"], [[], require_id, [node]])
            transformer.setProperty(require_expression, ["expression"], [require_func])
            return require_expression
        except Exception as err:
            print("Unable to add a require node\n", err)

    def check_owner(self, name):
        msg_sender = self.create_msg_sender()
        owner_judge = transformer.createNode("BinaryOperation")
        owner = self.create_identifier(name)
        transformer.setProperty(owner_judge, ["left", "operator", "right"], [msg_sender, "==", owner])
        require_node = self.add_check(owner_judge)
        return require_node

    def create_binary_operation(self, left, op, right):
        binop = transformer.createNode("BinaryOperation")
        transformer.setProperty(binop, ["left", "operator", "right"], [left, op, right])
        return binop

    def create_constructor(self, owner_name):
        try:
            constructor = transformer.createNode("FunctionDefinition")
            transformer.setProperty(constructor, ["name", "visibility", "modifiers", "isConstructor", "stateMutability", "returnParameters", "parameters"],
                                    [None, "public", [], True, None, None, []])
            parameter_list = transformer.createNode("ParameterList")
            transformer.setProperty(parameter_list, ["parameters"], [[]])
            block = transformer.createNode("Block")
            owner_assignment_stat = self.init_owner(owner_name)
            transformer.setProperty(block, ["statements"], [[owner_assignment_stat]])
            transformer.setProperty(constructor, ["body", "parameters"], [block, parameter_list])
            return constructor
        except Exception as err:
            print("Unable to create a constructor node.\n", err)

    def init_owner(self, owner_name):
        msg_sender = self.create_msg_sender()
        owner_assignment = transformer.createNode("BinaryOperation")
        owner = self.create_identifier(owner_name)
        transformer.setProperty(owner_assignment, ["left", "operator", "right"], [owner, "=", msg_sender])
        return self.to_expression_stat(owner_assignment)

    def to_expression_stat(self, node):
        expr_stat = transformer.createNode("ExpressionStatement")
        transformer.setProperty(expr_stat, ["expression"], [node])
        return expr_stat

