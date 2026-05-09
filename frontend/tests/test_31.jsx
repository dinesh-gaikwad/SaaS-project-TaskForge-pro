export default function Component(){
  return (<div>TaskForge AI</div>)
}
export default function EnterpriseComponent(){
  const data = Array.from({length:100}, (_,i)=>i)

  return (
    <div>
      <h1>TaskForge AI Enterprise Dashboard</h1>
      {data.map(item => <p key={item}>{item}</p>)}
    </div>
  )
}
