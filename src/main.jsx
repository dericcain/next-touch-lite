import React, { useMemo, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { CalendarDays, ChevronRight, CirclePlus, Clock3, Edit3, Flame, GripVertical, Pause, Play, RotateCcw, Save, SkipBack, SkipForward, Sparkles, Timer, Trophy, Waves, X } from 'lucide-react';
import './styles.css';

const initialActivities = [
  { title: 'Warm-Up', type: 'Warm-up', mins: 10, icon: Flame, notes: ['Movement prep', 'Ball mastery'] },
  { title: 'Rondo 4v2', type: 'Passing', mins: 12, icon: RotateCcw, notes: ['Two-touch maximum', 'Win it, switch'] },
  { title: 'Passing Pattern', type: 'Passing', mins: 15, icon: SkipForward, notes: ['Open body', 'Play with tempo'] },
  { title: 'Positional Play', type: 'Game', mins: 20, icon: Sparkles, notes: ['Find the free player'] },
  { title: 'Transition Game', type: 'Transition', mins: 15, icon: SkipForward, notes: ['React on loss'] },
  { title: 'Finishing', type: 'Finishing', mins: 15, icon: Trophy, notes: ['Quality over speed'] },
  { title: 'Set Pieces', type: 'Set piece', mins: 8, icon: Timer, notes: [] },
  { title: 'Cool Down', type: 'Recovery', mins: 5, icon: Waves, notes: ['Bring the group in'] },
];
const practices = [
  { title: 'Wednesday Training', date: 'Aug 1, 2026', activities: 8, duration: '1h 40m', status: 'On Watch' },
  { title: 'Friday Conditioning', date: 'Aug 2', activities: 7, duration: '1h 10m', status: 'Not on Watch' },
  { title: 'Saturday Skills', date: 'Aug 3', activities: 6, duration: '1h 00m', status: 'Not on Watch' },
  { title: 'Monday Team', date: 'Aug 4', activities: 9, duration: '1h 30m', status: 'Update Available' },
  { title: 'Wednesday Training', date: 'Aug 5', activities: 8, duration: '1h 40m', status: 'Not on Watch' },
];
const formatTotal = (items) => { const n = items.reduce((a, b) => a + b.mins, 0); return `${Math.floor(n / 60)}h ${String(n % 60).padStart(2, '0')}m`; };

function App() {
  const [screen, setScreen] = useState('library');
  const [items, setItems] = useState(initialActivities);
  const [saved, setSaved] = useState(false);
  const [watchState, setWatchState] = useState('preflight');
  const [active, setActive] = useState(1);
  const [remaining, setRemaining] = useState('4:12');
  const total = useMemo(() => formatTotal(items), [items]);
  const editItem = (i) => { const title = window.prompt('Activity title', items[i].title); if (title?.trim()) setItems(items.map((x, n) => n === i ? { ...x, title: title.trim() } : x)); };
  const addItem = () => setItems([...items, { title: 'New Activity', type: 'Custom', mins: 10, icon: Sparkles, notes: [] }]);
  const save = () => { setSaved(true); setTimeout(() => setSaved(false), 1800); };
  return <main className="app-shell">
    <aside className="sidebar"><div className="brand"><span className="brand-mark">N</span><span>NextTouch</span></div><div className="side-label">COACHING TOOLS</div><button className={screen === 'library' || screen === 'editor' ? 'nav active' : 'nav'} onClick={() => setScreen('library')}><CalendarDays size={18}/> Practices</button><button className="nav" onClick={() => setScreen('watch')}><Timer size={18}/> Watch companion</button><div className="sidebar-bottom"><div className="avatar">MC</div><div><strong>Marcus Chen</strong><small>Head coach</small></div></div></aside>
    <section className="workspace">{screen === 'watch' ? <Watch state={watchState} setState={setWatchState} active={active} setActive={setActive} remaining={remaining} setRemaining={setRemaining} items={items} total={total} /> : screen === 'editor' ? <Editor items={items} setItems={setItems} total={total} onBack={() => setScreen('library')} onAdd={addItem} onEdit={editItem} onSave={save} saved={saved} /> : <Library practices={practices} onOpen={() => setScreen('editor')} onWatch={() => setScreen('watch')} />}</section>
  </main>;
}

function Library({ practices, onOpen, onWatch }) { return <div className="page library"><header className="topbar"><div><p className="eyebrow">SATURDAY · AUGUST 1, 2026</p><h1>Practices</h1><p className="subhead">Build the plan. Coach the moment.</p></div><button className="primary small" onClick={onOpen}><CirclePlus size={17}/> New practice</button></header><section className="up-next"><div className="section-kicker">UP NEXT</div><div className="hero-practice" onClick={onOpen}><div className="hero-icon"><CalendarDays size={24}/></div><div className="hero-copy"><h2>Wednesday Training</h2><p><CalendarDays size={13}/> Today · 6:00 PM <span>·</span> 8 activities <span>·</span> 1h 40m</p></div><span className="hero-status">On Watch</span><ChevronRight size={20}/></div></section><div className="list-head"><h2>All practices</h2><span>5 plans</span></div><div className="practice-list">{practices.map((p, i) => <button className="practice-row" key={i} onClick={i === 0 ? onOpen : undefined}><div className="row-date"><CalendarDays size={18}/><span>{p.date}</span></div><div className="row-main"><strong>{p.title}</strong><small>{p.activities} activities <span>·</span> {p.duration}</small></div><span className={'status ' + p.status.toLowerCase().replaceAll(' ', '-')}>{p.status}</span><ChevronRight size={18}/></button>)}</div><div className="tip"><Sparkles size={17}/><div><strong>Ready for the weekend?</strong><p>Download your next plan to your watch before you head out.</p></div><button onClick={onWatch}>Open watch</button></div></div> }

function Editor({ items, total, onBack, onAdd, onEdit, onSave, saved }) { return <div className="page editor"><header className="editor-header"><button className="back" onClick={onBack}>← Back</button><div><p className="eyebrow">PRACTICE PLAN · REVISION 4</p><h1>Practice Editor</h1></div><button className="icon-button"><Edit3 size={18}/></button></header><div className="title-input"><input defaultValue="Wednesday Training"/><span>⌘E</span></div><div className="editor-meta"><div><span className="meta-label">SCHEDULED</span><strong><CalendarDays size={15}/> Today, 6:00 PM</strong></div><div><span className="meta-label">WATCH STATUS</span><strong className="watch-ok"><span className="dot"/> On Watch</strong></div><div className="sync-note">Changes create a new watch snapshot.</div></div><div className="timeline">{items.map((a, i) => <div className="activity" key={i}><div className="rail"><span>{i + 1}</span>{i < items.length - 1 && <i/>}</div><div className="activity-card" onClick={() => onEdit(i)}><div className="activity-icon"><a.icon size={18}/></div><div className="activity-copy"><strong>{a.title}</strong><small>{a.type}</small>{a.notes.slice(0, 2).map((n, j) => <em key={j}>• {n}</em>)}</div><b>{a.mins}m</b><GripVertical className="grip" size={18}/></div></div>)}</div><footer className="editor-footer"><div className="total"><strong>{items.length} activities</strong><span>·</span><strong>{total}</strong><small>Auto-saved locally</small></div><button className="outline" onClick={onAdd}><CirclePlus size={17}/> Add activity</button><button className="primary" onClick={onSave}>{saved ? 'Saved to Watch' : <><Save size={17}/> Save & sync</>}</button></footer></div> }

function Watch({ state, setState, active, setActive, remaining, setRemaining, items, total }) { const current = items[active]; const next = items[active + 1]; const running = state === 'running'; const expired = state === 'expired'; return <div className={'watch-page ' + state}><div className="watch-top"><button className="watch-exit" onClick={() => setState('preflight')}>‹</button><span>WATCH COMPANION</span><button className="watch-exit">•••</button></div>{state === 'preflight' ? <div className="watch-preflight"><div className="watch-eyebrow">READY TO COACH</div><h1>Wednesday<br/>Training</h1><div className="watch-stats"><span><Clock3 size={15}/> {total} total</span><span><CalendarDays size={15}/> Today · 6:00 PM</span><span><Sparkles size={15}/> 8 activities</span></div><button className="watch-primary" onClick={() => setState('running')}><Play size={20} fill="currentColor"/> Start practice</button><p className="offline"><span className="dot"/> Downloaded · ready offline</p></div> : <div className="live-content"><div className="live-context"><span>{total} total</span><strong>{active + 1} of {items.length}</strong></div><div className="live-title"><current.icon size={20}/><strong>{expired ? `Just finished ${current.title}` : current.title}</strong><button><span>Notes</span></button></div><div className="timer">{expired ? '0:00' : remaining}</div><div className="live-divider"/><div className="next-up"><span>NEXT UP</span><strong>{next ? next.title : 'Practice complete'}</strong>{next && <b>{next.mins}m</b>}</div><div className="transport"><button onClick={() => setActive(Math.max(0, active - 1))}><SkipBack size={22}/></button><button className="transport-main" onClick={() => setState(running ? 'paused' : 'running')}>{running ? <Pause size={22} fill="currentColor"/> : <Play size={22} fill="currentColor"/>}</button><button className="transport-next" onClick={() => { if (active < items.length - 1) { setActive(active + 1); setRemaining('12:00'); } else setState('expired'); }}><SkipForward size={22}/></button></div><button className="finish" onClick={() => setState('preflight')}>Finish practice</button>{state === 'paused' && <div className="paused-label">Paused</div>}</div>}</div> }

createRoot(document.getElementById('root')).render(<App />);
