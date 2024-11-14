# vFix

## Introduction
![Architecture of ContractPatch](architecture.png)
The increased adoption of smart contracts in many
industries has made them an attractive target for cybercriminals,
leading to millions of dollars in losses. Thus, continuously fixing
newly found vulnerabilities of smart contracts becomes a routine
software maintenance task for running smart contracts. However,
fixing the vulnerabilities that are specific to the smart contract
domain requires security knowledge that many developers lack.
Without effective tool support, this task can be very costly in
terms of manual labor.

To fill this critical need, in this paper, we propose VFIX,
which automatically generates security patches for vulnerable
smart contracts. In particular, VFIX provides a novel program
analysis framework that can incorporate different fix patterns
for fixing various types of vulnerabilities. To address the unique
challenges in accurately fixing smart contract vulnerabilities,
VFIX innovatively combines template-based repair with a set
of static program analysis techniques specially designed for
smart contracts. Specifically, given an input smart contract,
VFIX conducts ensemble identification based on multiple static
verification tools to identify vulnerabilities for an automatic fix.
Then, VFIX generates patches using template-based fix patterns,
and conducts static program analysis (e.g., program dependency
computation, pointer analysis) for smart contracts to accurately
infer and populate the parameter values for the fix templates.
Finally, VFIX performs static verification to ensure that the
patched contract is free of vulnerabilities. Our evaluations on 144
real smart contracts containing different types of vulnerabilities
show that VFIX can successfully fix 94% of the vulnerabilities and
preserve the expected normal behaviors of the smart contracts.

## Setup
<ol>
<li> Install the Secuerify: https://github.com/eth-sri/securify
<li> Install the Slither: https://github.com/crytic/slither
<li> Install the Smartcheck: https://github.com/smartdec/smartcheck
<li> Install the required packages listed in the package-lock.json
</ol>

## Input
<ol>
<li> The vulnerable smart contract
<li> processed the static tools' report
</ol>

## Output

The patched contract

## How to use
1. use Securify, Slither, and Smartcheck to find potential vulnerabilities
2. combine these three reports
3. use this combined static verification tools' results and contract as inputs for vFix
   
```bash
node top.js static-verification-reports-path smart-contract-path output-path
```

## Example

In the folder example, we provide some contracts with vulnerabilities, which can be used as the
input for the vFix. We also give the vFix patched contract which can
be used for users to verify the output of the installed vFix.

## Result

In the folder res, we upload the original data shown in our submission. The readme in the corresponding res
folder simply summarize our results. For more detailed explanation, please check our submission.
