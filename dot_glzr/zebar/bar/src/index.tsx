/* @refresh reload */
import './index.css';
import { render } from 'solid-js/web';
import { createStore } from 'solid-js/store';
import * as zebar from 'zebar';

const providers = zebar.createProviderGroup({
  komorebi: { type: 'komorebi' },
  date: { type: 'date', formatting: 'EEE d MMM t' },
  disk: { type: 'disk' },
  media: { type: 'media' },
  cpu: { type: 'cpu' },
  battery: { type: 'battery' },
  memory: { type: 'memory' },
});

render(() => <App />, document.getElementById('root')!);


function App() {
  function parseTitle(input: string) {
    // Regular expression to match strings ending with a file path to an executable
    const regex = /(\[\d+\/\d+\])\s.*\\([\w\d\-]+\.\w{2,4})$/;

    const match = input.match(regex);
    if (match) {
      return `${match[1]} ${match[2]}`;
    }

    return input;
  }

  function getBatteryIcon(batteryOutput: zebar.BatteryOutput) {
    if (batteryOutput.chargePercent > 90)
      return <i class="nf nf-fa-battery_4"></i>;
    if (batteryOutput.chargePercent > 70)
      return <i class="nf nf-fa-battery_3"></i>;
    if (batteryOutput.chargePercent > 40)
      return <i class="nf nf-fa-battery_2"></i>;
    if (batteryOutput.chargePercent > 20)
      return <i class="nf nf-fa-battery_1"></i>;
    return <i class="nf nf-fa-battery_0"></i>;
  }

  const [output, setOutput] = createStore(providers.outputMap);

  providers.onOutput(outputMap => setOutput(outputMap));

  return (
    <div class="app">
      <div class="left">
        <i class="logo nf nf-fa-windows"></i>

        {output.komorebi && (
          <>
            <div class="workspaces">
              {output.komorebi.currentWorkspaces.map(workspace => (
                <button
                  class={`workspace ${workspace.name === output.komorebi.focusedWorkspace.name && 'focused'}`}
                >
                  {workspace.name}
                </button>
              ))}
            </div>
            <div class="focused-window">
              <span>{parseTitle(output.komorebi.focusedWorkspace.tilingContainers[output.komorebi.focusedWorkspace.focusedContainerIndex]?.windows[0]?.title) ?? "-"}</span>
            </div>
          </>
        )}
      </div>

      <div class="center">
        <div class="date">{output.date?.formatted}</div>
      </div>

      <div class="right">
        <div class="media-container">
          {output.media && (
            <div class="media">
              <i class="nf nf-fa-music"></i>
              {output.media?.session?.title} -
              {output.media?.session?.artist}
            </div>
          )}
        </div>

        <div class="stats">
          {output.memory && (
            <div class="memory">
              <i class="nf nf-fae-chip"></i>
              {Math.round(output.memory.usage)}%
            </div>
          )}

          {output.cpu && (
            <div class="cpu">
              <span
                class={output.cpu.usage > 85 ? 'high-usage' : ''}
              >
                <i class="nf nf-oct-cpu"></i>
                {Math.round(output.cpu.usage)}%
              </span>
            </div>
          )}


          {output.disk && (
            <div class="disk">
              <i class="nf nf-fa-hdd_o"></i>
              {Math.round(100 - output.disk.disks[0].availableSpace.iecValue / output.disk.disks[0].totalSpace.iecValue * 100)}%
            </div>
          )}

          {output.battery && (
            <div class="battery">
              {output.battery.isCharging && (
                <i class="nf nf-md-power_plug charging-icon"></i>
              )}
              {getBatteryIcon(output.battery)}
              {Math.round(output.battery.chargePercent)}%
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
