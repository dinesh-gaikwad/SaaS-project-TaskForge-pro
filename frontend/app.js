const API="http://127.0.0.1:8000";
function scrollToId(id){document.getElementById(id).scrollIntoView({behavior:"smooth"})}
async function api(path,options){const r=await fetch(API+path,options);return r.json()}
async function load(){try{const s=await api("/api/dashboard");groupsStat.textContent=s.groups;resourcesStat.textContent=s.resources;quizStat.textContent=s.quizzes;tutorStat.textContent=s.tutors;loadGroups();loadTutors()}catch(e){console.log(e)}}
async function loadGroups(){const data=await api("/api/groups");groupGrid.innerHTML=data.map(g=>`<div class="card"><span class="eyebrow">${g.topic}</span><h3>${g.name}</h3><p class="muted">${g.members} learners · shared resources · live room</p><button class="ghost" onclick="scrollToId('rooms')">Join Room</button></div>`).join("")}
async function loadTutors(){const data=await api("/api/tutors");tutorGrid.innerHTML=data.map(t=>`<div class="card"><h3>${t.name}</h3><p class="muted">${t.skill}</p><strong>$${t.rate}/hr</strong><br><br><button class="primary">Book Session</button></div>`).join("")}
async function createDemoGroup(){await api("/api/groups",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({name:"Full Stack AI Squad",topic:"Software Engineering"})});loadGroups()}
async function sendChat(){const input=document.getElementById("chatInput");if(!input.value)return;const x=await api("/api/chat",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({user:"You",message:input.value})});messages.innerHTML+=`<p><b>${x.user}:</b> ${x.message}</p>`;input.value=""}
const canvas=document.getElementById("canvas"),ctx=canvas.getContext("2d");let drawing=false,last=null;
canvas.addEventListener("pointerdown",e=>{drawing=true;last=pos(e)});
canvas.addEventListener("pointerup",()=>{drawing=false;last=null});
canvas.addEventListener("pointermove",e=>{if(!drawing)return;const p=pos(e);ctx.beginPath();ctx.moveTo(last.x,last.y);ctx.lineTo(p.x,p.y);ctx.strokeStyle="#55e6a5";ctx.lineWidth=3;ctx.stroke();last=p});
function pos(e){const r=canvas.getBoundingClientRect();return{x:(e.clientX-r.left)*canvas.width/r.width,y:(e.clientY-r.top)*canvas.height/r.height}}
load();