#!/usr/bin/env python3
"""Install shared agent configuration, preserving local edits and backups."""
import argparse,datetime,fcntl,hashlib,json,os,pathlib,shutil,sys,tempfile

def fingerprint(path):
    if not path.exists() and not path.is_symlink():return None
    digest=hashlib.sha256()
    entries=[path]
    if path.is_dir() and not path.is_symlink():entries+=sorted(path.rglob('*'))
    for item in entries:
        relative=str(item.relative_to(path))
        if item.is_symlink():record=[relative,'symlink',os.readlink(item)]
        elif item.is_dir():record=[relative,'directory',item.stat().st_mode & 0o111]
        elif item.is_file():record=[relative,'file',item.stat().st_mode & 0o111,hashlib.sha256(item.read_bytes()).hexdigest()]
        else:raise ValueError('Unsupported filesystem entry: '+str(item))
        digest.update((json.dumps(record,ensure_ascii=True)+'\n').encode())
    return digest.hexdigest()

def desired(source,home,stage):
    items=[]
    for group,target in [('agents-skills','.agents/skills'),('codex-skills','.codex/skills')]:
        root=source/group
        if root.exists():
            for skill in sorted(root.iterdir()):
                if not skill.is_dir() or skill.name.startswith('.'):continue
                if not (skill/'SKILL.md').is_file():raise ValueError('Invalid skill: '+skill.name)
                dest=stage/target/skill.name
                shutil.copytree(skill,dest,symlinks=False)
                items.append((str(pathlib.Path(target)/skill.name),dest))
    instructions=source/'AGENTS.md'
    if instructions.exists():
        dest=stage/'.codex/AGENTS.md';dest.parent.mkdir(parents=True,exist_ok=True)
        dest.write_text(instructions.read_text().replace('/home/txemaleon',str(home)))
        dest.chmod(0o600);items.append(('.codex/AGENTS.md',dest))
    return items

def install(source,home,adopt=False,check=False):
    state=home/'.local/state/environment-sync';state.mkdir(parents=True,exist_ok=True,mode=0o700)
    with (state/'lock').open('w') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        previous=json.loads((state/'installed.json').read_text()) if (state/'installed.json').exists() else {}
        with tempfile.TemporaryDirectory(prefix='stage-',dir=state) as tmp:
            items=desired(source,home,pathlib.Path(tmp))
            missing=sorted(set(previous)-{name for name,_ in items})
            if missing:
                print(json.dumps({'missing_from_source':missing,'changed':False}));return 2
            changes=[];conflicts=[];new_state={}
            for name,candidate in items:
                current=fingerprint(home/name);expected=fingerprint(candidate)
                new_state[name]=expected
                if current==expected:continue
                if current is not None and current!=previous.get(name) and not adopt:conflicts.append(name)
                changes.append((name,candidate,current))
            if conflicts:
                print(json.dumps({'conflicts':conflicts,'changed':False}));return 2
            if check:
                print(json.dumps({'pending':[x[0] for x in changes]}));return 3 if changes else 0
            backup=state/'backups'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
            applied=[]
            try:
                for name,candidate,old_hash in changes:
                    dest=home/name
                    if fingerprint(dest)!=old_hash:raise RuntimeError('Concurrent edit: '+name)
                    saved=backup/name
                    dest.parent.mkdir(parents=True,exist_ok=True)
                    if dest.exists() or dest.is_symlink():
                        saved.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
                        shutil.move(str(dest),saved)
                    applied.append((dest,saved))
                    os.replace(candidate,dest)
                manifest=state/'installed.json.tmp';manifest.write_text(json.dumps(new_state,indent=2)+'\n')
                manifest.chmod(0o600);os.replace(manifest,state/'installed.json')
            except Exception:
                for dest,saved in reversed(applied):
                    if dest.is_symlink() or dest.is_file():dest.unlink()
                    elif dest.exists():shutil.rmtree(dest)
                    if saved.exists() or saved.is_symlink():shutil.move(str(saved),dest)
                raise
            print(json.dumps({'installed':len(changes),'managed':len(items),'backup':str(backup) if backup.exists() else None}));return 0

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source',type=pathlib.Path,required=True)
    p.add_argument('--home',type=pathlib.Path,default=pathlib.Path.home())
    p.add_argument('--adopt',action='store_true',help='Back up and adopt existing local differences during initial setup.')
    p.add_argument('--check',action='store_true',help='Report pending changes without installing.')
    a=p.parse_args()
    if not a.source.is_dir():p.error('source directory does not exist')
    try:return install(a.source.resolve(),a.home.resolve(),a.adopt,a.check)
    except Exception as e:
        print(type(e).__name__+': '+str(e),file=sys.stderr);return 1
if __name__=='__main__':sys.exit(main())
