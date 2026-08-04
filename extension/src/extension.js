/**
 * Weftspun 3D Studio, as an editor extension.
 *
 * One command. It opens a panel, starts a real Elixir VM in that
 * panel, and shows what the VM answered. The checks run on AtomVM,
 * compiled to WebAssembly by Popcorn, so a result here is a result
 * from Elixir and not from JavaScript that imitates it.
 *
 * The extension targets VSCodium, so it uses no proprietary API and
 * publishes to Open VSX. It runs in Visual Studio Code as well.
 */
const vscode = require('vscode');
const { openMinimalTestPanel } = require('./popcornPanel');

/**
 * @param {import('vscode').ExtensionContext} context
 */
function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand('weftspun.runMinimalTest', () => {
      openMinimalTestPanel(context);
    }),
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
