const textareaArray = document.getElementsByTagName("textarea");
const textareaMob = textareaArray[0];
const textareaDesk = textareaArray[1];

textareaDesk.oninput = function(){
  textareaDesk.style.height = "auto";
  textareaDesk.style.height = `${textareaDesk.scrollHeight}px`;
};

textareaMob.oninput = function(){
  textareaMob.style.height = "auto"
  textareaMob.style.height = `${textareaMob.scrollHeight}px`
};
