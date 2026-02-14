<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>动物塑人格测试（终极版）</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<style>
body{
  font-family:-apple-system,BlinkMacSystemFont,"PingFang SC","Microsoft YaHei",sans-serif;
  background:#111;
  color:#fff;
  padding:20px;
  max-width:700px;
  margin:auto;
}
h1{text-align:center;margin-bottom:30px;color:#ffa500;}
.question{margin-bottom:25px;}
label{
  display:block;
  padding:6px 10px;
  margin:4px 0;
  border-radius:6px;
  background:rgba(255,255,255,0.05);
  cursor:pointer;
  transition:0.2s;
}
label:hover{background:rgba(255,255,255,0.15);}
input[type="radio"]{margin-right:8px;}
button{
  width:100%;
  padding:12px;
  margin-top:15px;
  background:linear-gradient(90deg,#ff6b6b,#ffa500);
  border:none;
  color:#fff;
  font-size:16px;
  border-radius:12px;
  cursor:pointer;
  transition:0.3s;
}
button:hover{background:linear-gradient(90deg,#ffa500,#ff6b6b);}
canvas{
  max-width:100%;
  aspect-ratio:1/1;
}
.result{display:none;margin-top:30px;padding:15px;border-radius:12px;}
.analysis-section{margin-top:15px;margin-bottom:25px;}
.analysis-section h3{margin-bottom:5px;color:#ffa500;}
.animal-icon{
  width:80px;
  height:80px;
  display:inline-block;
  margin:0 10px;
}
</style>
</head>
<body>

<h1>🐾 动物塑人格测试（终极版）</h1>

<div id="quiz"></div>
<button id="submitBtn">查看结果</button>

<div class="result" id="result">
  <div style="text-align:center;margin-bottom:15px;">
    <img id="mainAnimalIcon" class="animal-icon" alt="主型动物图标">
    <img id="subAnimalIcon" class="animal-icon" alt="副型动物图标">
  </div>
  <h2 id="animalName"></h2>
  <canvas id="radarChart"></canvas>
  <div id="analysis"></div>
</div>

<script>
// -------------------- 题目 --------------------
const questions=[
{q:"1. 当进入一个新环境，你更倾向？", a:[{text:"直接成为焦点",type:"虎"}, {text:"观察后掌控局面",type:"狼"}, {text:"用魅力吸引注意",type:"豹"}, {text:"轻松融入再影响",type:"狐"}, {text:"安静建立稳定感",type:"熊"}]},
{q:"2. 冲突时你的第一反应？", a:[{text:"正面压制",type:"虎"}, {text:"冷静分析",type:"狼"}, {text:"优雅反击",type:"豹"}, {text:"侧面化解",type:"狐"}, {text:"退一步再处理",type:"熊"}]},
{q:"3. 你更害怕？", a:[{text:"被忽视",type:"虎"}, {text:"失控",type:"狼"}, {text:"失去吸引力",type:"豹"}, {text:"被限制",type:"狐"}, {text:"不被需要",type:"熊"}]},
{q:"4. 你理想的状态？", a:[{text:"绝对主导",type:"虎"}, {text:"精准掌控",type:"狼"}, {text:"优雅猎杀",type:"豹"}, {text:"自由灵动",type:"狐"}, {text:"稳固安全",type:"熊"}]},
{q:"5. 你走路的感觉？", a:[{text:"强势",type:"虎"}, {text:"稳重",type:"狼"}, {text:"流畅",type:"豹"}, {text:"轻快",type:"狐"}, {text:"厚重",type:"熊"}]},
{q:"6. 你更适合穿搭？", a:[{text:"硬挺结构",type:"虎"}, {text:"极简轮廓",type:"狼"}, {text:"曲线贴身",type:"豹"}, {text:"飘逸层次",type:"狐"}, {text:"宽松包裹",type:"熊"}]},
{q:"7. 拍照时的姿态？", a:[{text:"直视镜头",type:"虎"}, {text:"微表情控制",type:"狼"}, {text:"侧身曲线",type:"豹"}, {text:"动态抓拍",type:"狐"}, {text:"放松自然",type:"熊"}]},
{q:"8. 你的身体语言？", a:[{text:"侵略性",type:"虎"}, {text:"克制",type:"狼"}, {text:"性感",type:"豹"}, {text:"灵动",type:"狐"}, {text:"沉稳",type:"熊"}]},
{q:"9. 表达愤怒方式？", a:[{text:"直接爆发",type:"虎"}, {text:"冷处理",type:"狼"}, {text:"带刺反击",type:"豹"}, {text:"玩笑化解",type:"狐"}, {text:"内化消化",type:"熊"}]},
{q:"10. 对竞争的态度？", a:[{text:"必赢",type:"虎"}, {text:"策略",type:"狼"}, {text:"游戏",type:"豹"}, {text:"随机",type:"狐"}, {text:"无所谓",type:"熊"}]},
{q:"11. 面对挑战？", a:[{text:"主动出击",type:"虎"}, {text:"精准布局",type:"狼"}, {text:"试探靠近",type:"豹"}, {text:"变化路线",type:"狐"}, {text:"等待时机",type:"熊"}]},
{q:"12. 别人对你的第一印象？", a:[{text:"压迫",type:"虎"}, {text:"冷静",type:"狼"}, {text:"性感",type:"豹"}, {text:"灵动",type:"狐"}, {text:"安全",type:"熊"}]},
{q:"13. 对规则的态度？", a:[{text:"打破",type:"虎"}, {text:"利用",type:"狼"}, {text:"变通",type:"豹"}, {text:"绕开",type:"狐"}, {text:"遵守",type:"熊"}]},
{q:"14. 喜欢的能量？", a:[{text:"强烈",type:"虎"}, {text:"冷峻",type:"狼"}, {text:"性感",type:"豹"}, {text:"轻盈",type:"狐"}, {text:"温厚",type:"熊"}]},
{q:"15. 理想伴侣气场？", a:[{text:"能对抗",type:"虎"}, {text:"能匹配",type:"狼"}, {text:"能欣赏",type:"豹"}, {text:"能陪玩",type:"狐"}, {text:"能依靠",type:"熊"}]},
{q:"16. 你更像？", a:[{text:"战士",type:"虎"}, {text:"指挥官",type:"狼"}, {text:"猎手",type:"豹"}, {text:"游侠",type:"狐"}, {text:"守护者",type:"熊"}]},
{q:"17. 穿搭关键词？", a:[{text:"结构",type:"虎"}, {text:"线条",type:"狼"}, {text:"曲线",type:"豹"}, {text:"层次",type:"狐"}, {text:"体积",type:"熊"}]},
{q:"18. 喜欢的颜色？", a:[{text:"黑红",type:"虎"}, {text:"黑白灰",type:"狼"}, {text:"豹纹/金属",type:"豹"}, {text:"浅色跳色",type:"狐"}, {text:"大地色",type:"熊"}]},
{q:"19. 吸引人的方式？", a:[{text:"威慑",type:"虎"}, {text:"距离感",type:"狼"}, {text:"性感",type:"豹"}, {text:"可爱",type:"狐"}, {text:"安全感",type:"熊"}]},
{q:"20. 人生主题？", a:[{text:"征服",type:"虎"}, {text:"控制",type:"狼"}, {text:"诱导",type:"豹"}, {text:"自由",type:"狐"}, {text:"稳定",type:"熊"}]}
];

// -------------------- 构建题目 --------------------
const scores={虎:0,狼:0,豹:0,狐:0,熊:0};
const quiz=document.getElementById("quiz");
questions.forEach((item,i)=>{
  let div=document.createElement("div");
  div.className="question";
  div.innerHTML=`<p>${i+1}. ${item.q}</p>`;
  item.a.forEach(ans=>{
    div.innerHTML+=`<label><input type="radio" name="q${i}" value="${ans.type}"> ${ans.text}</label>`;
  });
  quiz.appendChild(div);
});

// -------------------- 动物配色和图标 --------------------
const animalTheme={
  "虎":{color:"#ff6b6b",icon:"https://upload.wikimedia.org/wikipedia/commons/5/56/Tiger_icon.svg"},
  "狼":{color:"#36a2eb",icon:"https://upload.wikimedia.org/wikipedia/commons/0/0e/Wolf_icon.svg"},
  "豹":{color:"#f0c419",icon:"https://upload.wikimedia.org/wikipedia/commons/3/3c/Cheetah_icon.svg"},
  "狐":{color:"#ffa500",icon:"https://upload.wikimedia.org/wikipedia/commons/1/12/Fox_icon.svg"},
  "熊":{color:"#8b5a2b",icon:"https://upload.wikimedia.org/wikipedia/commons/0/08/Bear_icon.svg"}
};

// -------------------- 完整 25 种组合分析 --------------------
const comboAnalysis={
"虎-虎":"<div class='analysis-section'><h3>虎-虎</h3><p>你充满力量和自信，行动果断，适合领导角色。</p></div>",
"虎-狼":"<div class='analysis-section'><h3>虎-狼</h3><p>主导+冷静，善于策略和行动兼顾，稳中带攻。</p></div>",
"虎-豹":"<div class='analysis-section'><h3>虎-豹</h3><p>力量+魅力，既有霸气又有吸引力，适合冒险与展示。</p></div>",
"虎-狐":"<div class='analysis-section'><h3>虎-狐</h3><p>果敢+灵动，善于机智处理复杂局面，行动灵活。</p></div>",
"虎-熊":"<div class='analysis-section'><h3>虎-熊</h3><p>力量+稳重，充满安全感但不失霸气，领导力强。</p></div>",
"狼-虎":"<div class='analysis-section'><h3>狼-虎</h3><p>冷静+力量，策略性强，同时能果断执行计划。</p></div>",
"狼-狼":"<div class='analysis-section'><h3>狼-狼</h3><p>冷静理性，善于分析和布局，擅长掌控全局。</p></div>",
"狼-豹":"<div class='analysis-section'><h3>狼-豹</h3><p>理性+魅力，分析能力强且具吸引力，能带动他人合作。</p></div>",
"狼-狐":"<div class='analysis-section'><h3>狼-狐</h3><p>策略+灵活，擅长解决问题，随机应变能力强。</p></div>",
"狼-熊":"<div class='analysis-section'><h3>狼-熊</h3><p>稳重+理性，行动稳健可靠，适合守护与规划。</p></div>",
"豹-虎":"<div class='analysis-section'><h3>豹-虎</h3><p>魅力+力量，既优雅又霸气，适合展现个人能力。</p></div>",
"豹-狼":"<div class='analysis-section'><h3>豹-狼</h3><p>魅力+策略，优雅但心思缜密，适合社交与领导兼顾。</p></div>",
"豹-豹":"<div class='analysis-section'><h3>豹-豹</h3><p>优雅而自信，外表吸引力强，同时行动敏捷。</p></div>",
"豹-狐":"<div class='analysis-section'><h3>豹-狐</h3><p>魅力+灵动，善于与环境互动，轻松影响周围人。</p></div>",
"豹-熊":"<div class='analysis-section'><h3>豹-熊</h3><p>魅力+稳重，吸引力强且可靠，给人安全感。</p></div>",
"狐-虎":"<div class='analysis-section'><h3>狐-虎</h3><p>灵动+力量，机智果敢，善于处理变化多端的局面。</p></div>",
"狐-狼":"<div class='analysis-section'><h3>狐-狼</h3><p>灵活+理性，善于计划又不失变通，适应力强。</p></div>",
"狐-豹":"<div class='analysis-section'><h3>狐-豹</h3><p>灵动+魅力，轻松吸引他人，同时具行动力。</p></div>",
"狐-狐":"<div class='analysis-section'><h3>狐-狐</h3><p>自由灵动，善于随机应变，行动轻快敏捷。</p></div>",
"狐-熊":"<div class='analysis-section'><h3>狐-熊</h3><p>灵动+稳重，善于调整步调，行动灵活又可靠。</p></div>",
"熊-虎":"<div class='analysis-section'><h3>熊-虎</h3><p>稳重+力量，可靠且有安全感，同时具备决断力。</p></div>",
"熊-狼":"<div class='analysis-section'><h3>熊-狼</h3><p>稳重+理性，沉着冷静，擅长守护和规划。</p></div>",
"熊-豹":"<div class='analysis-section'><h3>熊-豹</h3><p>稳重+魅力，给人安全感又有吸引力，适合守护和影响他人。</p></div>",
"熊-狐":"<div class='analysis-section'><h3>熊-狐</h3><p>稳重+灵动，行动可靠又不失灵活，适合团队协作。</p></div>",
"熊-熊":"<div class='analysis-section'><h3>熊-熊</h3><p>稳重可靠，踏实安全，充满安全感和守护力。</p></div>"
};

// -------------------- 计算结果 --------------------
let radarChart=null;
function calculate(){
  for(let key in scores){scores[key]=0;}
  for(let i=0;i<questions.length;i++){
    let selected=document.querySelector(`input[name="q${i}"]:checked`);
    if(selected){scores[selected.value]++;}
  }
  let sortedTypes=Object.entries(scores).sort((a,b)=>b[1]-a[1]);
  let mainType=sortedTypes[0][0];
  let subType=sortedTypes[1][0];

  document.getElementById("result").style.display="block";
  document.getElementById("animalName").innerText=`你的动物塑类型：${mainType}（主型） + ${subType}（副型）`;
  document.getElementById("result").style.background=`linear-gradient(120deg, ${animalTheme[mainType].color}33, ${animalTheme[subType].color}33)`;
  document.getElementById("mainAnimalIcon").src=animalTheme[mainType].icon;
  document.getElementById("subAnimalIcon").src=animalTheme[subType].icon;

  renderChart(mainType,subType);

  const key=`${mainType}-${subType}`;
  document.getElementById("analysis").innerHTML = comboAnalysis[key] || "<p>暂无分析内容</p>";
}

// -------------------- 雷达图 --------------------
function renderChart(main,sub){
  const ctx=document.getElementById("radarChart");
  if(radarChart){radarChart.destroy();}
  radarChart=new Chart(ctx,{
    type:'radar',
    data:{
      labels:["力量感","冷感度","攻击性","柔韧度","野性度"],
      datasets:[
        {label:main,data:getData(main),backgroundColor:animalTheme[main].color+"33",borderColor:animalTheme[main].color,borderWidth:2},
        {label:sub,data:getData(sub),backgroundColor:animalTheme[sub].color+"33",borderColor:animalTheme[sub].color,borderWidth:2}
      ]
    },
    options:{responsive:true,maintainAspectRatio:true,scales:{r:{beginAtZero:true,max:5}}}
  });
}

function getData(type){
  const map={虎:[5,3,5,2,4],狼:[4,5,4,2,3],豹:[3,4,3,4,5],狐:[2,3,2,5,4],熊:[5,2,3,3,2]};
  return map[type];
}

// -------------------- 事件绑定 --------------------
document.getElementById("submitBtn").addEventListener("click", calculate);
</script>
</body>
</html>
