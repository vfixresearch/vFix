const appRoot = require("app-root-path");
const parser = require(appRoot + "/src/solidity-parser-antlr/src/index");

let Generator = {
  source: [],
  text: "",
  
  // Main function to run generator
  run: function(ast) {
    Generator.source = [];
    Generator.text = "";

    let currentContractName = null;
    let brackets = [];
    let signals = { prev: [], post: [] };
    let version = 0.4;

    let parseParameter = node => {
      if (node.typeName.type === "ArrayTypeName") {
        Generator.source.push(node.typeName.baseTypeName.name, "[", "]");
      } else if (node.typeName.type === "ElementaryTypeName") {
        Generator.source.push(node.typeName.name);
      }
      if (node.name) Generator.source.push(node.name);
    };

    // AST traversal with streamlined visitor methods
    parser.visit(ast, {
      PragmaDirective: node => {
        Generator.source.push("pragma", node.name, node.value, ";");
        version = parseFloat(node.value.slice(3)) || version;
      },
      ContractDefinition: node => {
        Generator.source.push(node.kind, node.name);
        currentContractName = node.name;
        if (node.baseContracts.length) Generator.source.push("is");
        brackets.push("}");
      },
      StateVariableDeclaration: node => {
        brackets.push(";");
      },
      VariableDeclarationStatement: node => {
        Generator.source.push("var");
        brackets.push(";");
      },
      VariableDeclaration: node => {
        if (node.name) Generator.source.push(node.name);
      },
      UsingForDeclaration: node => {
        Generator.source.push("using", node.libraryName, "for;");
      },
      FunctionDefinition: node => {
        Generator.source.push(node.isConstructor && version > 0.4 ? "constructor" : "function");
        if (node.isConstructor) Generator.source.push(currentContractName);
        else Generator.source.push(node.name || "");
        if (node.returnParameters) Generator.source.push("returns");
        brackets.push(node.body ? "{" : ";");
      },
      Block: node => {
        Generator.source.push("{");
        brackets.push("}");
      },
      IfStatement: node => {
        Generator.source.push("if", "(");
        signals.prev.push({ id: node.trueBody.id, type: ")" });
      },
      WhileStatement: node => {
        Generator.source.push("while", "(");
        signals.prev.push({ id: node.body.id, type: ")" });
      },
      ForStatement: node => {
        Generator.source.push("for", "(");
        signals.prev.push({ id: node.body.id, type: ")" });
      },
      BreakStatement: node => {
        Generator.source.push("break;");
      },
      EmitStatement: node => {
        Generator.source.push("emit;");
      },
      ReturnStatement: node => {
        Generator.source.push("return;");
      },
      Identifier: node => {
        Generator.source.push(node.name);
      },
      FunctionCall: node => {
        Generator.source.push(node.names?.length ? "(" : ")");
      },
      BooleanLiteral: node => {
        Generator.source.push(node.value);
      }
    });

    // Final processing
    while (brackets.length) Generator.source.push(brackets.pop());
    Generator.format();
    return Generator.text;
  },

  format: () => {
    Generator.text = "";
    let tabCnt = 0;
    for (const token of Generator.source) {
      if (token === "{") tabCnt += 1;
      else if (token === "}") tabCnt -= 1;
      
      if (Generator.text.endsWith("\n")) Generator.text += "    ".repeat(tabCnt);
      else if (Generator.text && ![",", ";", ".", "(", "["].includes(token[0])) Generator.text += " ";

      Generator.text += token;
      if (["{", "}", ";"].includes(token)) Generator.text += "\n";
    }
  }
};

module.exports = Generator;
