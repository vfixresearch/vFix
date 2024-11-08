import os

class ReportParser:
    def get_file_name(self, output):
        try:
            filename = []
            for contract in output.keys():
                head = contract.rfind("/")
                tail = contract.rfind(".sol:")
                name = contract[head + 1:tail]
                if name not in filename:
                    filename.append(name)
            return filename
        except Exception as err:
            print("Unable to get the filename.\n", err)

    def get_contracts(self, output):
        try:
            contracts = []
            for contract in output.keys():
                head = contract.rfind(".sol:")
                contract_name = contract[head + 5:]
                if contract_name not in contracts:
                    contracts.append(contract_name)
            return contracts
        except Exception as err:
            print("Unable to get the contract names.\n", err)

    def get_violations(self, output, contract_name):
        try:
            violations = {}
            for contract, data in output.items():
                if contract_name in contract:
                    for vulnerability, details in data["results"].items():
                        violations[vulnerability] = details["violations"]
            return violations
        except Exception as err:
            print("Unable to get the violations of this contract.\n", err)

    def get_contracts_and_violations(self, output):
        try:
            violations = {}
            for contract, data in output.items():
                head = contract.rfind(".sol:")
                contract_name = contract[head + 5:]
                violations[contract_name] = {}
                for vulnerability, details in data["results"].items():
                    violations[contract_name][vulnerability] = details["violations"]
            return violations
        except Exception as err:
            print("Unable to get all violations.\n", err)

    def get_total_violation_num(self, output):
        try:
            num = {"total": 0}
            for data in output.values():
                for vulnerability, details in data["results"].items():
                    if vulnerability not in num:
                        num[vulnerability] = 0
                    violation_count = len(details["violations"])
                    num["total"] += violation_count
                    num[vulnerability] += violation_count
            return num
        except Exception as err:
            print("Unable to get total number of violations.\n", err)

    def get_one_violation(self, violation_name, violations):
        try:
            new_violations = []
            for contract_violations in violations.values():
                if violation_name in contract_violations:
                    for violation in contract_violations[violation_name]:
                        new_violations.append(violation + 1)
            return new_violations
        except Exception as err:
            print("Unable to get the single violation record.\n", err)
