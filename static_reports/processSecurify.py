import os
import json
from src import solidity_parser_antlr as parser
from src import utils
from src.SecurifyReportParser import reportparser

# Updated folder paths
res_folder = "/home/Yuxi/.."
securify_report_folder = '..'
combine_result_folder = ''

# List of files in the specified folders
securify_report_list = os.listdir(securify_report_folder)
combine_result_list = os.listdir(combine_result_folder)

def process_original_securify_based_on_multiple_detector(securify_res, multiple_res, address):
    for contract, data in securify_res.items():
        if address in contract:
            for vulnerability, results in data.get('results', {}).items():
                if vulnerability == "DAO":
                    violations = results.get('violations', [])
                    multiple_res_dao = multiple_res.get("DAO", {})

                    if violations:
                        print(f"{address} Previous violations: {violations}")
                        modified_violations = [
                            v for v in violations if (v + 1) in multiple_res_dao and multiple_res_dao[v + 1] > 1
                        ]
                        if len(modified_violations) != len(violations):
                            results['violations'] = modified_violations
                        print(f"{address} final violations: {results['violations']}")

# Process each report in the combine result list
for combine_result_name in combine_result_list:
    address = combine_result_name.split('-')[0]
    securify_result_name = f"{address}.json"
    combine_result_abs_path = os.path.join(combine_result_folder, combine_result_name)
    securify_report_abs_path = os.path.join(securify_report_folder, securify_result_name)

    with open(securify_report_abs_path, 'r') as f:
        securify_pure_output = json.load(f)
    with open(combine_result_abs_path, 'r') as f:
        combine_res = json.load(f)

    process_original_securify_based_on_multiple_detector(securify_pure_output, combine_res, address)

    final_report_path = os.path.join(res_folder, f"{address}-final.json")
    with open(final_report_path, 'w') as f:
        json.dump(securify_pure_output, f, indent=4)
