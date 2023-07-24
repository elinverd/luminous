export function sendFileToClient(url, filename) {
  var link = document.createElement("a");
  link.setAttribute("href", url);
  link.setAttribute("download", filename);
  link.style.visibility = 'hidden';
  link.setAttribute("target", "_blank")
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}
