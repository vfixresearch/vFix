import app_root
from src import ast_transformer as transformer
from src import advancedtransformer as ad

class PostProcessor:

    def handle_missing_input_validation(self, violations, ast):
        try:
            res = []
            for contract, data in violations.items():
                for line in data.get("MissingInputValidation", []):
                    funcs = transformer.findNodeByLine(ast, line + 1)
                    for func in funcs:
                        if func['type'] == "FunctionDefinition" and func['loc']['start']['line'] == line + 1:
                            parameters = ad.getParameters(func)
                            addressnum = sum(1 for param in parameters.values() if param == "address")
                            nonaddresses = [param for param, typ in parameters.items() if typ != "address"]

                            if not parameters or all(param != "address" for param in parameters.values()):
                                continue

                            requires = [
                                funccall for funccall in transformer.findNodeByType(func, "FunctionCall")
                                if funccall['expression']['type'] == "Identifier" and funccall['expression']['name'] == "require"
                            ]
                            addresschecked = sum(
                                1 for param in parameters if parameters[param] == "address" and any(
                                    req['arguments'][0]['type'] == "BinaryOperation" and 
                                    req['arguments'][0]['left']['type'] == "Identifier" and 
                                    req['arguments'][0]['left']['name'] == param 
                                    for req in requires
                                )
                            )

                            if addressnum <= addresschecked:
                                continue

                            checked = {param: False for param in nonaddresses}
                            for nonaddr in nonaddresses:
                                for req in requires:
                                    calls = transformer.findNodeByType(req, "FunctionCall")
                                    if not calls and transformer.findNodeByName(req, nonaddr):
                                        checked[nonaddr] = True

                            if not all(checked.values()):
                                continue
                            
                            if line + 1 not in res:
                                res.append(line + 1)
            return res
        except Exception as err:
            print("Unable to process MissingInputValidation vulnerabilities.\n", err)

    def handle_locked_ether(self, violations, ast):
        try:
            res = []
            for contract, data in violations.items():
                for line in data.get("LockedEther", []):
                    funcs = transformer.findNodeByLine(ast, line + 1)
                    for func in funcs:
                        if (func['type'] == "ContractDefinition" and func['loc']['start']['line'] == line + 1 and 
                                func.get('kind') == "contract" and line + 1 not in res):
                            res.append(line + 1)
            return res
        except Exception as err:
            print("Unable to process LockedEther vulnerabilities.\n", err)

    def handle_unhandled_exception(self, violations, ast):
        try:
            res = []
            for contract, data in violations.items():
                for line in data.get("UnhandledException", []):
                    funcs = transformer.findNodeByLine(ast, line + 1)
                    for func in funcs:
                        if func['type'] == "ExpressionStatement" and func['loc']['start']['line'] == line + 1:
                            binops = transformer.findNodeByType(func, "BinaryOperation")
                            if any(binop['operator'] == "=" for binop in binops):
                                continue
                            if line + 1 not in res:
                                res.append(line + 1)
            return res
        except Exception as err:
            print("Unable to process UnhandledException vulnerabilities.\n", err)

    def handle_dao(self, violations, ast):
        try:
            res = []
            for contract, data in violations.items():
                for line in data.get("DAO", []):
                    funcs = transformer.findNodeByLine(ast, line + 1)
                    for func in funcs:
                        if func['type'] == "ExpressionStatement" and func['loc']['start']['line'] == line + 1:
                            globalfunc = transformer.findIncludedGlobalDef(ast, func)
                            assignments = transformer.findStateVariable(globalfunc, 4, func['id'])
                            statements = (
                                transformer.findNodeByType(globalfunc, "IfStatement") + 
                                transformer.findNodeByType(globalfunc, "DoWhileStatement") + 
                                transformer.findNodeByType(globalfunc, "WhileStatement")
                            )

                            notincluded = True
                            statements_func_calls = [
                                stmt for statement in statements 
                                for stmt in transformer.findNodeByType(statement, "ExpressionStatement")
                            ]
                            statements_binops = [
                                stmt for statement in statements 
                                for stmt in transformer.findNodeByType(statement, "BinaryOperation")
                            ]

                            if func in statements_func_calls or any(assignment in statements_binops for assignment in assignments):
                                notincluded = False
                            if any(transformer.findNodeByName(assign, "now") for assign in assignments):
                                continue
                            if notincluded and line + 1 not in res:
                                res.append(line + 1)
            return res
        except Exception as err:
            print("Unable to process DAO vulnerabilities.\n", err)

    def handle_unrestricted_write(self, violations, ast):
        res = []
        return res

    def handle_all(self, violations, ast):
        newviolations = {
            "DAO": self.handle_dao(violations, ast),
            "UnhandledException": self.handle_unhandled_exception(violations, ast),
            "LockedEther": self.handle_locked_ether(violations, ast),
            "MissingInputValidation": self.handle_missing_input_validation(violations, ast),
            "UnrestrictedWrite": self.handle_unrestricted_write(violations, ast)
        }
        return newviolations
