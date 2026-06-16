#!/usr/bin/env python3
import sys
import json
import subprocess

def clean_cmd(cmd):
    # Strip leading/trailing whitespace and quote characters if paired
    stripped = cmd.strip()
    has_quotes = False
    if len(stripped) >= 2 and stripped.startswith('"') and stripped.endswith('"'):
        stripped = stripped[1:-1].strip()
        has_quotes = True
    elif len(stripped) >= 2 and stripped.startswith("'") and stripped.endswith("'"):
        stripped = stripped[1:-1].strip()
        has_quotes = True
    return stripped, has_quotes

def restore_cmd(cmd, has_quotes):
    if has_quotes:
        return f'"{cmd}"'
    return cmd

def main():
    try:
        input_str = sys.stdin.read()
        input_data = json.loads(input_str)
    except Exception as e:
        sys.stderr.write(f"agpipe-wrapper json parse error: {str(e)}\n")
        print(json.dumps({"decision": "allow"}))
        sys.exit(0)

    tool_name = input_data.get("tool_name")
    is_antigravity = (tool_name == "run_command")
    has_quotes = False

    if is_antigravity:
        orig_tool_input = input_data.get("tool_input", {})
        command_line = orig_tool_input.get("CommandLine", "")
        
        # Clean the command line to remove external quotes
        command_cleaned, has_quotes = clean_cmd(command_line)
        
        # Build simulated payload for rtk hook gemini
        simulated_payload = {
            "tool_name": "run_shell_command",
            "tool_input": {
                "command": command_cleaned
            }
        }
    else:
        simulated_payload = input_data

    # Call the real rtk hook gemini
    try:
        proc = subprocess.run(
            ["rtk", "hook", "gemini"],
            input=json.dumps(simulated_payload),
            text=True,
            capture_output=True
        )
        stdout = proc.stdout.strip()
        stderr = proc.stderr
        
        if stderr:
            sys.stderr.write(stderr)
            sys.stderr.flush()
            
        if proc.returncode != 0:
            sys.exit(proc.returncode)
            
        output_data = json.loads(stdout)
    except Exception as e:
        sys.stderr.write(f"agpipe-wrapper exec error: {str(e)}\n")
        print(json.dumps({"decision": "allow"}))
        sys.exit(0)

    # Translate the decision back if we mapped it
    if is_antigravity and output_data.get("decision") == "ask_user":
        rewritten_cmd = output_data.get("hookSpecificOutput", {}).get("tool_input", {}).get("command")
        if rewritten_cmd:
            restored = restore_cmd(rewritten_cmd, has_quotes)
            output_data["hookSpecificOutput"]["tool_input"] = {
                "CommandLine": restored
            }
            
    print(json.dumps(output_data))

if __name__ == "__main__":
    main()
