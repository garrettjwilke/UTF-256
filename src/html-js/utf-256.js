(() => {
  const fileInput = document.getElementById('fileInput');
  const exportBtn = document.getElementById('exportBtn');
  const status = document.getElementById('status');

  let processedData = null;
  let action = ''; // 'encode' or 'decode'
  let originalFileName = '';

  function showStatus(msg, isError = false) {
    status.textContent = msg;
    status.style.color = isError ? 'red' : 'green';
  }

  function readFileAsArrayBuffer(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = () => reject(reader.error);
      reader.readAsArrayBuffer(file);
    });
  }

  function isUTF256(buffer) {
    const arr = new Uint8Array(buffer);
    for (let b of arr) {
      if (b !== 0x00 && b !== 0xFF) return false;
    }
    return true;
  }

  function encodeUTF256(inputBuffer) {
    const input = new Uint8Array(inputBuffer);
    const output = new Uint8Array(input.length * 8);
    for (let idx = 0; idx < input.length; idx++) {
      const byte = input[idx];
      for (let bit = 7; bit >= 0; bit--) {
        const bitVal = (byte >> bit) & 1;
        output[idx * 8 + (7 - bit)] = bitVal ? 0xFF : 0x00;
      }
    }
    return output;
  }

  function decodeUTF256(inputBuffer) {
    const input = new Uint8Array(inputBuffer);
    if (input.length % 8 !== 0) {
      throw new Error("Input length must be a multiple of 8 bytes.");
    }
    const output = new Uint8Array(input.length / 8);
    for (let i = 0; i < output.length; i++) {
      let byte = 0;
      for (let j = 0; j < 8; j++) {
        const val = input[i * 8 + j];
        if (val === 0x00) {
          byte = byte << 1;
        } else if (val === 0xFF) {
          byte = (byte << 1) | 1;
        } else {
          throw new Error(`Invalid byte in UTF-256 file: 0x${val.toString(16).padStart(2, '0')}`);
        }
      }
      output[i] = byte;
    }
    return output;
  }

  async function handleFileImport() {
    if (!fileInput.files.length) {
      showStatus("Please select a file first.", true);
      return;
    }
    const file = fileInput.files[0];
    originalFileName = file.name;

    try {
      const buffer = await readFileAsArrayBuffer(file);

      if (isUTF256(buffer)) {
        // Looks like UTF-256, decode it
        processedData = decodeUTF256(buffer);
        action = 'decode';
        showStatus(`File detected as UTF-256. Decoded successfully. Ready to export.`);
      } else {
        // Otherwise encode
        processedData = encodeUTF256(buffer);
        action = 'encode';
        showStatus(`File detected as UTF-8. Encoded successfully. Ready to export.`);
      }
      exportBtn.disabled = false;
    } catch (e) {
      showStatus(`Error processing file: ${e.message}`, true);
      exportBtn.disabled = true;
      processedData = null;
    }
  }

  function handleExport() {
    if (!processedData) {
      showStatus("No processed data to export.", true);
      return;
    }
    const blob = new Blob([processedData], { type: "application/octet-stream" });
    const url = URL.createObjectURL(blob);

    const a = document.createElement("a");
    a.href = url;

    let prefix = action === 'encode' ? 'encoded_' : 'decoded_';
    a.download = prefix + originalFileName;

    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    showStatus(`File exported as ${a.download}`);
  }

  fileInput.addEventListener('change', handleFileImport);
  exportBtn.addEventListener('click', handleExport);
})();