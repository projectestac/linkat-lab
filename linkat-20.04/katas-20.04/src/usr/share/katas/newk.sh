#!/bin/bash
# newk
# v. 0.26
# This is Free Software under GNU GPL v3.0 or a BSD-3-Clause, as you prefer.
# Copyright 2021 Reynaldo Cordero Corro, Mercedes Cordero Martínez
#
# * To start a new Haskell kata, lean and clean, ready to BDD/TDD, in few seconds.
#   It uses *stack* and *hpack*. Ready to use QuickCheck and Hspec
#
# * To create a kata, start by giving as parameters:
#   * the name of the kata,
#   * the link of the exercise prepared for the kata and
#   * (an optional) comment.
#
#  As a result, you will obtain a kata environment and:
#    * A directory bookmarking application pointing at the kata   [cdargs]
#    * A initial commit for a control version application         [git]
#    * Ready to edit source and testing code with some help       [emacs + Dante]
#
# * The library will be placed next to the other libraries in a directory you can set.
#
# * Tested using stack Version 2.7.1 and hpack 0.34.4.
#
## Main usage:
#    newk KATANAME REF [COMMENT]
#    newk KATANAME
#
## Features:
# * It provides a workflow related to training katas. See USAGE variable, ahead.

U="\033[4m"  # underline ON
B="\033[1m"  # bold ON
B_="\033[0m" # bold OFF  (every other mark is OFF too)
T="\033]0;"  # Title ON  (Set Terminal caption)
T_="\007"    # Title OFF

LBLUE_B="\e[104m" # Light blue (background)
LCYAN="\e[96m"    # Light cyan
LGRAY="\e[37m"    # Light gray
LGREEN="\e[92m"   # Light green

AZ_L="abcdefghijklmnopqrstuvwxyz"
AZ_U="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
NU="0123456789"
CODEWARS="www.codewars.com"

## Kata directory root:
#GITLAB_GITHUB="GITHUB"
GITLAB_GITHUB="GITLAB"
#LIBROOT_CW="${HOME}/git/${GITLAB_GITHUB}/CW"
LIBROOT_CW="${HOME}/haskellkatas"

## Some other variables:
#RESOLVER="lts-16.23"  # LTS 16.23 for ghc-8.8.4,  published 2020-11-21
#RESOLVER="lts-18.0"   # LTS 18.0  for ghc-8.10.4, published 2021-06-16
RESOLVER="lts-18.15"   # LTS 18.15 for ghc-8.10.7, published 2021-11-03
W2QUIT="/tmp/w2quit"   # To easily close windows

TERMINAL_NAMES=("stack ghci" "git diff" "stack build" "Command - git")
EDITOR_NAME="KATA: "

GITLOGT='git log --graph --pretty=format:'\
'"%C(red)%h%C(reset)%C(green) (%cd)%C(reset)%n %s%C(yellow)%d"'\
' --date=format:"%Y-%m-%d %H:%M:%S" --branches'
GITLOGT_="git log --graph --pretty=format:%h --branches  | sed '0,/ \* /{s/ \* /\n/}' | sed 's/[| /*]//g'"

GITLOGT_MOST_RECENT='git log ${BRNCH} -n1 --pretty=format:'\
'"%C(red)%h%C(reset) %s%C(yellow)%d"'\
' --date=format:"%Y-%m-%d %H:%M:%S"'

GITLOGT_MOST_RECENT_='git log ${BRNCH} -n1 --pretty=format:%h'

#GITLOGT_MOST_RECENT_MESSAGE='git log $BRNCH -n1 --pretty=format:%s'
GITLOGT_MOST_RECENT_MESSAGE='echo -n -e "${B}${LCYAN}"; git log ${BRNCH} -n1 --pretty=format:%s'

## geometry: lines x columns + px horizontal + px vertical
GEOM_EMACS="72x25+589+15"  # editor (Emacs)
GEOM_TERM1="65x29+0+15"    # Term1
GEOM_TERM2="65x26+0+610"   # Term2
GEOM_TERM3="75x26+589+650" # Term3
GEOM_TERM0="65x55+0+15"    # Term0 (hidden)

P_CAT_HASKELL="pygmentize -f terminal256 -O style=native -l haskell"

PROGRAM_NAME="$(basename "$0")"
INSTRUCTIONS="${PROGRAM_NAME} --log"
README="cat README.md"

SRC_FILE=$(echo src/*)  # It must match only one file
TEST_FILE=$(echo test/?*Spec.hs)  # It must match only one file

TEMPDIR=".stack-work/newk/"

## COMMITS="git rev-list --count $(git branch --show-current)"
## COMMITS_MASTER="git rev-list --count master"

function commits_current_branch() {
  git rev-list --count $(git branch --show-current)
}


function exist_branch_XX(){
  p="${1}"
  if [[ -z "${p}" ]]; then
    echo "Parameter missing."
    exit 1
  fi
  git branch | grep -w "${p}" # if-then-else: Non empty string means true. Empty string means false.
}


function commits_branch_XX() {
  p="${1}"
  if [[ -z "${p}" ]]; then
    echo "Parameter missing"
    exit 1
  fi
  if [[ $(exist_branch_XX ${p}) ]]; then
    :
  else
    echo "Branch does not exist"
    exit 1
  fi
  git rev-list --count "${p}"
}

BRANCHwip="git branch --show-current | grep -E '^wip .*' | wc -c"

USAGE="${B}${PROGRAM_NAME}${B_}: Haskell Kata training. (v. 0.26)

${PROGRAM_NAME} KATANAME [REF] [COMMENT]

${PROGRAM_NAME} [-h|--help] | [-p|--present] | [-q|--quit]
${PROGRAM_NAME} [-1|--first-red]
${PROGRAM_NAME} [-2|--extended-tests]
${PROGRAM_NAME} [-3|--next]
${PROGRAM_NAME} [-0|--log] | [-00|--log2] | [-000|--log3] ...
${PROGRAM_NAME} [-s|--show | [-sf|--show-fast]
${PROGRAM_NAME} [-c|--compare] C1 C2 [C3]

where:
  -h|--help            show this help text
  -p|--present         present kata's windows (editor & terminals)
  -q|--quit            quit windows (aka. close all & exit)

  -1|--first-red       do once when your kata is completely set up
  -2|--extended-tests  commit your own kataficated solution (on branch 00)
  -3|--next            commit a kataficated solution. Start a new branch

  -s|--show            show solutions
 -sf|--show-fast       show solutions   (No syntax parsing)
  
  -c|--compare C1 C2 [C3]   compare between solutions 

  KATANAME             must begin with a letter
                       and contain only alphanumeric char
  REF                  reference. i.e.:
                       webpage of the kata training problem
  COMMENT              Some info about the kata (give a title is nice)
                       (enclose the COMMENT phrase into single quotes)
  BRANCH               Git's branch
    00:          Your solution will be placed here
    01, 02, etc: Other solutions will be placed there

Typical usage:
  ${PROGRAM_NAME} KATANAME REF [COMMENT]
     -> set up a brand new kata and open an editor
          and 3 bash terminals with tools.
     -> if kataName already exists, you will be asked
        if you want to work on it
Examples:
  ${PROGRAM_NAME} multiply https://www.codewars.com/kata/50654ddff44f800200000004/train/haskell 'Multiply is an easy kata'
  ${PROGRAM_NAME} greet    https://www.codewars.com/kata/523b4ff7adca849afe000035/train/haskell 'Second kata'
  ${PROGRAM_NAME} multiply
"

# Options and parameters
while [[ $# -gt 0 ]]
do
key="${1}"

case ${key} in
    -h|--help)
    HELP=YES
    shift
    ;;
    -q|--quit)
    QUIT=YES
    shift
    ;;
    -1|--first-red)
    K1=YES
    shift
    ;;
    -2|--extended-tests)
    K2=YES
    shift
    ;;
    -3|--next)
    K3=YES
    shift
    ;;
    -0|--log)
    LOG=YES
    shift
    ;;
    -00|--log2)
    LOG2=YES
    shift
    ;;
    -000|--log3)
    LOG3=YES
    shift
    ;;
    -0000|--log4)
    LOG4=YES
    shift
    ;;
    -s|--show)
    SHOW=YES
    shift
    ;;
    -sf|--show-fast)
    SHOW=YES
    FAST=YES
    shift
    ;;
    -c|--compare)
    COMPARE=YES
    shift
    ;;
    -p|--present)
    PRESENT=YES
    shift
    ;;
    *)
    POSITIONAL+=("${1}") # save it in an array for later
    shift # past argument
    ;;
esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ ${POSITIONAL:0:1} == "-" ]]; then
  echo -e "\n${B}Unknown option${B_}: -> ${POSITIONAL}\n"
  HELP=YES
fi
####


function check()
{
if [[ "${HELP}" == "YES" ]]; then
  echo
  echo -e "${USAGE}"
  exit 0
fi

if [[ "${LOG}" == "YES" || "${LOG2}" == "YES" || "${LOG3}" == "YES" || "${LOG4}" == "YES" ]]; then
  k0
  exit 0
fi

if [[ "${K1}" == "YES" ]]; then
  k1 ""
  exit 0
fi

if [[ "${K2}" == "YES" ]]; then
  k2 ""
  exit 0
fi

if [[ "${K3}" == "YES" ]]; then
  k3 ""
  exit 0
fi

if [[ "${SHOW}" == "YES" ]]; then
  show
  exit 0
fi

if [[ "${COMPARE}" == "YES" ]]; then
  compare ${1} ${2} ${3}
  exit 0
fi

if [[ "${QUIT}" == "YES" ]]; then
  quit_windows
  exit 0
fi

if [[ "${PRESENT}" == "YES" ]]; then
  present_windows
  exit 0
fi

NAME=`eval "echo '${1}' | sed 's/[/]//g'"`  # strip slashes. Useful when you are in LIBROOT directory, and use autocompletation(TAB) to get kata's name
REF="${2}"
COMMENT="${3}"

if [[ "${NAME}" =~ [^${AZ_L}${AZ_U}${NU}]+ ]] ; then
  echo
  echo -e "Error: ${B}${NAME}${B_} must only contain alphanumeric characters. It must begin with a letter."
  echo
  exit 1
fi

case "${NAME:0:1}" in
  [${AZ_L}] | [${AZ_U}])
    # echo "${NAME} begin with a letter. It's Okay."
    :
    ;;
  "")
    echo
    echo -e "Error: ${B}No kataName provided!${B_}"
    echo
    echo "Examples:
  ${PROGRAM_NAME} multiply https://www.codewars.com/kata/50654ddff44f800200000004/train/haskell 'Multiply is an easy kata'
  ${PROGRAM_NAME} greet    https://www.codewars.com/kata/523b4ff7adca849afe000035/train/haskell 'Second kata'
  ${PROGRAM_NAME} multiply"
    echo
    echo -e "For more information: ${B}${PROGRAM_NAME} --help${B_}"
    echo    
    exit 1
    ;;
  *)
    echo
    echo -e "Error: ${B}${NAME}${B_} is not allowed. It must begin with a letter. Try again."
    echo
    exit 1
    ;;
esac

LIB_U=`eval "echo ${NAME} | sed 's/^./\u&/'"`  # NameOfTheNewLib. First letter to uppercase
LIB_L=`eval "echo ${NAME} | sed 's/^./\l&/'"`  # NameOfTheNewLib. First letter to lowercase

if [ -z "${LIB_L}"  ]; then
  echo
  echo -e "${USAGE}"
  exit 1
fi

CW_T=""
HR_T=""
if [ -d "${LIBROOT_CW}/${LIB_L}" ]; then
  CW_T="CW"
  echo
  echo "Kata found in ${LIBROOT_CW}/${LIB_L}"
  echo
  echo "- - - - - - - - -"
  echo
fi

if [[ ${CW_T} == "CW" ]] ; then
  echo -e "'${B}${LIB_L}${B_}' name has already used. (CodeWars)"
  echo -e -n "Reopen kata '${B}${LIB_L}${B_}' (CodeWars) ?"
  echo -n " [Y/n] " ; read -e answ
  if [[ "${answ}" == "" ]] || [[ "${answ}" == "y" ]] || [[ "${answ}" == "Y" ]]; then
    EDIT_EXISTING_KATA="YES"
    LIBROOT=${LIBROOT_CW}
    CW_T="EDIT"
  fi
fi

if [[ ${CW_T} == "CW" ]]; then
  echo "Then bye!"
  exit 1
fi

REF_T=$(echo "${REF}" | tr '[:upper:]' '[:lower:]')

if [[ ${CW_T} == "EDIT" ]] ; then
  echo
  echo -e "Reopen kata '${B}${LIB_L}${B_}'"
elif [ -z "${REF}" ] && [ -z "${CW_T}" ] ; then
  echo
  echo -e "When creating a new kata... Error: ${B}REF${B_} missing."
  echo
  echo -e "${PROGRAM_NAME} KATANAME ${B}REF${B_} ${B}[COMMENT]${B_}"
  echo
  exit 1
elif [ -z "${CW_T}" ] &&  [[ ${REF_T} =~ ${CODEWARS} ]] ; then
  echo
  echo -e "Create kata '${B}${LIB_L}${B_}' (CodeWars)."
  LIBROOT="${LIBROOT_CW}"
else
  echo
  echo -e "Remember that REF must be from ${B}${CODEWARS}${B_}."
  exit 1
fi

if [ ! -d "${LIBROOT}" ]; then
  echo "You're going to create this root directory to store your katas:"
  echo
  echo -e "  ${B}${LIBROOT}${B_}"
  echo
  echo -n "Do you want to proceed?"
  echo -n " [Y/n] " ; read -e answ
  if [[ "${answ}" == "" ]] || [[ "${answ}" == "y" ]] || [[ "${answ}" == "Y" ]]; then
    mkdir -p "${LIBROOT}"
  else
    echo " Bye!"
    exit 1
  fi
fi
}


function quit_windows()
{
pkill -f "${EDITOR_NAME}"
for i in ${!TERMINAL_NAMES[@]}; do
  pkill -f "${TERMINAL_NAMES[$i]}"
done
}


function present_windows()
{
EDITOR_WINDOW=$( xdotool search --name "${EDITOR_NAME}" )
TERMINAL_WINDOWS0=$( xdotool search --name "${TERMINAL_NAMES[0]}" )
TERMINAL_WINDOWS1=$( xdotool search --name "${TERMINAL_NAMES[1]}" )
TERMINAL_WINDOWS2=$( xdotool search --name "${TERMINAL_NAMES[2]}" )
TERMINAL_WINDOWS3=$( xdotool search --name "${TERMINAL_NAMES[3]}" )

xdotool windowactivate --sync "${EDITOR_WINDOW}"
xdotool windowactivate --sync "${TERMINAL_WINDOWS0}"
xdotool windowactivate --sync "${TERMINAL_WINDOWS1}"
xdotool windowactivate --sync "${TERMINAL_WINDOWS2}"
xdotool windowactivate --sync "${TERMINAL_WINDOWS3}"
}


function checkUpdatedTests()
{
test=$(git diff test)
if [[ "${test}" == "" ]]; then
  :
else
  echo "New tests!"
  oriBranch=$(git branch --show-current)
  git stash --quiet -- test
  other=$(git diff)
  if [[ "${other}" == "" ]]; then
    if [[ $(exist_branch_XX master_base) ]] ; then
      git checkout --quiet master_base
      git checkout --quiet stash@{0} -- test
      echo "Tests updated:"
      git commit -am "First red (tests updated) (${oriBranch})"
      git checkout --quiet ${oriBranch}
      git stash pop --quiet
    else
      :
      # git checkout --quiet master_base
      git checkout --quiet stash@{0} -- test
      echo "Tests updated:"
      git commit -am "Tests updated (${oriBranch})"
      git checkout --quiet ${oriBranch}
      git stash pop --quiet
    fi
  else
    if [[ $(exist_branch_XX master_base) ]] ; then
      git stash --quiet -- .
      git checkout --quiet master_base
      git checkout --quiet stash@{1} -- test
      echo "Tests updated:"
      git commit -am "First red (tests updated) (${oriBranch})"
      git checkout --quiet ${oriBranch}
      git stash pop --quiet
      git stash pop --quiet
    else
      :
      git stash --quiet -- .
      # git checkout --quiet master_base
      git checkout --quiet stash@{1} -- test
      echo "Tests updated:"
      git commit -am "Tests updated (${oriBranch})"
      git checkout --quiet ${oriBranch}
      git stash pop --quiet
      git stash pop --quiet
    fi
  fi
fi
}


function k1()
{
error=$(stack build --test --fast 2>&1 >/dev/null)
error_last_line=$(echo "${error}" | tail -n1)

expand_current_branch() {
  git branch --show-current
}
expand_on_master() {
  echo $(expand_current_branch) | grep "^master$"
}
expand_commits_master() {
  git rev-list --count master
}

MATCH="test passed$"

if [ "${error_last_line}" != "Logs printed to console" ] ; then
  echo
  echo -e "${B}ERROR${B_}:  ${B}${PROGRAM_NAME} -1${B_}  script doesn't apply."
  echo -e "Your code must compile, but it mustn't pass tests (${B}RED${B_})"
  echo
  exit
else
  if [ ! -z expand_on_master ]; then
    echo "git commit -am 'First red'"
    git commit -am 'First red'
    k0
  else
    echo
    echo -e "${B}ERROR${B_}:  ${B}${PROGRAM_NAME} -1${B_}  script doesn't apply."
    echo -e "You are not on branch ${B}master${B_}."
    echo -e "(You are on branch ${B}$(expand_current_branch){B_})"
    echo
    exit
  fi
fi
}


function k2()
{
WIP=$1  # WIP="WIP" or WIP=""
current_branch=$( git branch --show-current )
mm=$(echo ${current_branch} | grep "master")

stack build --test --fast >/dev/null 2>&1

if [ "$?" -ne 0 ] ; then
  echo
  echo -e "${B}ERROR${B_}:  ${B}${PROGRAM_NAME} -2${B_}  script doesn't apply."
  echo -e "Code ${B}must pass${B_} tests. (${B}GREEN${B_})"
  echo
  exit 1
else
  if [[ $(exist_branch_XX 00) ]] ; then
    echo
    echo -e "${B}ERROR${B_}:  ${B}${PROGRAM_NAME} -2${B_}  script doesn't apply."
    echo
    echo -e "Branch '00' exists. It seems that you've already executed  ${B}${PROGRAM_NAME} -2${B_}."
    echo
    exit 1
  fi
  if [[ ! "$(git log --pretty=format:'%s' | grep "First red")" =~ ^"First red" ]]; then
    echo
    echo -e "${B}ERROR${B_}:  ${B}${PROGRAM_NAME} -2${B_}  script doesn't apply."
    echo
    echo -e "It seems that you haven't executed  ${B}${PROGRAM_NAME} -1${B_}  before"
    echo
    exit 1
  fi
  git log --oneline --branches
  echo
  echo -e "Please, enter a commit message: (${B}CTRL-C to cancel${B_})"
  read -e COMMIT_MESSAGE

  checkUpdatedTests
  if git add test/ && git commit -m 'First red (tests updated)' ; then
    echo
    echo "extended tests"
    echo
    echo    "This is your current log now:"
    eval ${GITLOGT}
  else
    echo
    echo -e "${B}NO${B_} extended tests"
  fi
  echo
  git stash 1> /dev/null && echo "Stashed the solution and create basic branches" \
    && git checkout -b master_base && git checkout -b 00 \
    && git stash pop  1> /dev/null
  echo "Popped back the solution"
  echo
  git commit -am "00 ${COMMIT_MESSAGE}"
  git checkout master_base && git checkout -b 01
  k0
fi
}


function k3()
{
  nextXX()
  {
  var3="00"
  while IFS= read -r line ; do
    var1="${line:2:2}"
    var2="${var1//[!0-9]/}"
    if [ ${#var2} -eq 2 ] ; then
      if [ "${var2}" \> "${var3}" ]; then
        var3=${var2}
      fi
    fi
  done < <(git branch)
  NEXT_BRANCH_XX=$(( $(( 10#${var3} )) + 1))
  NEXT_BRANCH_XX=$( printf '%02d' ${NEXT_BRANCH_XX} )
  }

if [[ ! $(exist_branch_XX 00) ]] ; then
  echo
  echo -e "${B}ERROR${B_}:  ${B}${PROGRAM_NAME} -2${B_}  script doesn't apply."
  echo
  if [ $(commits_branch_XX $(git branch --show-current)) == "1" ] ; then
    echo -e "It seems that you haven't executed  ${B}${PROGRAM_NAME} -1${B_}  before"
  else
    echo -e "It seems that you haven't executed  ${B}${PROGRAM_NAME} -2${B_}."
  fi
  echo
  k0
  exit 1
fi

echo "Just be patient..."
output=$(stack build --test --fast 2>&1)

echo ${output} | grep -E "Process exited with code: ExitFailure 1$" >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
  compile_time_error="compile_time_error"
else
  compile_time_error=""
fi

echo $output | grep -E "exited with: ExitFailure 1 Logs printed to console$" >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
  dont_pass_test="dont_pass_test"
else
  dont_pass_test=""
fi

### echo "dont_pass_test= $dont_pass_test"
### echo "compile_time_error= $compile_time_error"

if [[ ${compile_time_error} ]] || [[ ${dont_pass_test} ]] ; then
  echo
  echo -e "${B}ERROR${B_}:  ${B}${PROGRAM_NAME} -3${B_}  script doesn't apply."
  echo -e "Code ${B}must pass${B_} tests. (${B}GREEN${B_})"
  echo
  exit 1
else

  ###  git log --oneline --branches
  $PROGRAM_NAME -0000
  echo
  echo -e "Commit your kataficated code. After that you'll be moved to ${B}NEXT${B_} branch.\n(${B}CTRL-C to cancel${B_})"
  echo -e "Please, enter a commit message: "
  read -e COMMIT_MESSAGE
  checkUpdatedTests
  git commit -am "$(git branch --show-current) ${COMMIT_MESSAGE}"

  if [ "$?" -ne 0 ] ; then
    echo "ERROR when commit!"
    exit 1
  fi

  nextXX
  git checkout master_base 2> /dev/null && (git checkout -b "${NEXT_BRANCH_XX}" 2> /dev/null || git checkout "${NEXT_BRANCH_XX}" 2> /dev/null)
  echo -e "(Switched to a new branch '${B}${NEXT_BRANCH_XX}${B_}')"
  k0
fi
}


function show()
{

console=$(tty)
echo "Just be pacient..."  | tee "${console}" > /dev/null 2>&1

a1=$(echo -e "${B}${LBLUE_B}================== Heads of all solution branches${B_}"
  function gitlogt_most_recent_f()
  {
    var=0
    GITLOGT_MOST_RECENT_='git log $BRNCH -n1 --pretty=format:%h'

    while [ $? -eq 0 ]
    do
      BRNCH=$( printf '%02d' ${var} )
      var=$(( var + 1 ))
      eval ${GITLOGT_MOST_RECENT_}w 2> /dev/null
    done
  }

index=0

readarray -dw -t linesArray <<<"$(gitlogt_most_recent_f)"

for commit in "${linesArray[@]}"
do
  size=${#commit}
  if [ "${size}" -lt 7 ]; then
    return
  else
    bb=$(git branch --contains ${commit} | grep "master_base")
    if [ -z "${bb}" ]; then
      padindex=$(printf %03d "${index}")
      echo -e "${LGRAY}-----------------------------------------------------${B_}"
      echo -e "${LGRAY}-- ${padindex} ${SRC_FILE}${B_}"
      echo -e "${B}${LCYAN}$(git log -n1 --pretty=format:"-- %s%d" "${commit}")${B_} ${commit}"
      if [[ ! $FAST == "YES" ]] ; then
        echo    "$(git show "${commit}:./${SRC_FILE}")" | eval ${P_CAT_HASKELL}
      else
        echo -e "${LGREEN}"
        echo    "$(git show "${commit}:./${SRC_FILE}")"
        echo -e "${B_}"
      fi
      index=$(( index + 1 ))
    fi
  fi
done)

if [[ ! ${FAST} == "YES" ]] ; then
  echo "${a1}" | less -R
else
  echo "${a1}"
fi

}

function createfiles()
{
  mkdir -p $TEMPDIR

  file2=$(echo $(echo $SRC_FILE | sed 's/\//./g' ))  # src.Multiply.hs

  function gitlogt_f()
  {
    var=0
    gitlogt_="git log --pretty=format:%h --branches --graph | sed '0,/ \* /{s/ \* /\n/}' | sed 's/[| /*]//g'"

    eval ${gitlogt_} 2> /dev/null
  }

index=0
indexE=0

readarray -t linesArray <<<"$(gitlogt_f)"

for commit in "${linesArray[@]}"
do
  size=${#commit}
  if [ "$size" -lt 7 ]; then
    :
  else
    outf="$TEMPDIR${commit}.$file2"
    if [ -f $outf ]; then
      # echo "$outf"
      indexE=$(( indexE + 1 ))
    else
      # echo "=> $outf"
      git log -n1 --pretty=tformat:"-- %s%d" "$commit"  > $outf
      git show $commit:./$(echo $SRC_FILE)             >> $outf
      index=$(( index + 1 ))
    fi
  fi
done
#echo "Created files:  $index"
#echo "Existent files: $indexE"
}

function compare() #C1 #C2 #[C3]
{
  error=""
  meld=""
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "$PROGRAM_NAME [-c|--compare] C1 C2 [C3]"
  else
    createfiles
    if [ ! -f ${TEMPDIR}$1* ]; then
      echo "First parameter (Short Commit ID) are not OK:  ($1)"
      error="ERROR"
    fi
    if [ ! -f ${TEMPDIR}$2* ]; then
      echo "Second parameter (Short Commit ID) are not OK: ($2)"
      error="ERROR"
    fi
    if [ -z "$3" ]; then
      meld="MELD2"
    else
      if [ -f ${TEMPDIR}$3* ]; then
        meld="MELD3"
      else
        echo "Third (optional) parameter (Short Commit ID) are not OK: ($3)"
        error="ERROR"
      fi
    fi
    if [ "$error" == "ERROR" ]; then
      exit
    else
      #createfiles
      if [ "$meld" == "MELD2" ]; then
        meld ${TEMPDIR}$1* ${TEMPDIR}$2*
      elif [ "$meld" == "MELD3" ]; then
        meld ${TEMPDIR}$1* ${TEMPDIR}$2* ${TEMPDIR}$3*
      fi
    fi
  fi
}


function k0()
{
if [ ! -d ".git" ]; then
  echo
  echo "There's no git repository here."
  echo "No git log to show!"
  echo
  exit 1
fi

LIB_U=`eval "basename ${PWD} | sed 's/^./\u&/'"`  # NameOfTheLib. First letter to uppercase

if   [[ ${PWD} =~ ${LIBROOT_CW} ]]  ; then
  KATA_GALORE="CodeWars"
else
  KATA_GALORE="KATA_GALORE"
fi

if [[ "${LOG4}" == "YES" ]]; then
  LOG3="YES"
  GITLOGT_MOST_RECENT=${GITLOGT_MOST_RECENT_MESSAGE}
fi

if [[ "${LOG3}" == "YES" ]]; then
# git branch -v --format="%(subject)" | uniq
var=0
a1=$(while [ $? -eq 0 ]
  do
    echo
    BRNCH=$( printf '%02d' ${var} )
    var=$(( var + 1 ))
    eval ${GITLOGT_MOST_RECENT} 2> /dev/null
  done

  echo -n -e "${B_}")

 if [[ "${LOG4}" == "YES" ]]; then
  echo -e "${a1}"
 else
  echo -e "${a1}" | less -R
 fi
 
  exit 0
elif [[ "${LOG2}" == "YES" ]]; then
  var=0
  while [ $? -eq 0 ]
  do
    BRNCH=$( printf '%02d' ${var} )
    var=$((var + 1))
    eval ${GITLOGT_MOST_RECENT} 2> /dev/null
  done
else
  echo
  echo "This is your current log:"
  echo
  eval ${GITLOGT} 2> /dev/null
fi

echo "*******************"
git status
echo "*******************"
echo

if [[ $(exist_branch_XX "00") ]] ; then
  echo -e "${U}Next steps${B_}:"
  echo -e "1) take a solution from ${KATA_GALORE} and update your local file:"
  echo -e "  1.1) ${B}src/${LIB_U}.hs${B_}"
  echo -e "2) ${B}kataficate${B_} code"
  echo -e "3) use ${B}${PROGRAM_NAME} -3${B_}"
  echo -e "   to commit changes and create a new branch to work on next solution"
  echo

# boilerplate
#elif [[ $(commits_branch_XX $(git branch --show-current)) == "1" ]] ; then
elif [[ $(git branch --show-current) == "master" ]] && [[ $(commits_branch_XX "master") == "1" ]]; then
  sleep 0.4
  echo -e    "${U}Next steps${B_}:"
  echo -e    "1) Go to ${KATA_GALORE} and update these local files:"
  echo -e    "  1.1) ${B}src/${LIB_U}.hs${B_}       (types, parameters)"
  echo -e    "  1.1) ${B}test/${LIB_U}Spec.hs${B_}  ('it' elements)"
  echo -e    "2) ${B}get a RED${B_} (code compile fine and do not pass tests)"
  echo -e    "3) then run  ${B}${PROGRAM_NAME} -1${B_}  to commit your 'first red'"
  echo -e    "   and follow the new instructions you'll see."
  echo

# first red. Create wip branch if needed  git log --pretty=format:'%s' -1
#elif [[ $(commits_branch_XX $(git branch --show-current)) == "2" ]] ; then
elif [[ "$(git log --pretty=format:'%s' -1)" =~ ^"First red" ]]; then
  echo -e "${U}Next steps${B_}:"
  echo -e "1) ${B}Compose a solution${B_} (${B}GREEN${B_})."
  echo -e "2) ${B}Kataficate${B_} your code"
  echo -e "3) Validate your code at the ${B}${KATA_GALORE}${B_} website"
  echo -e "4) fetch ${B}extended tests${B_} from ${KATA_GALORE}."
  echo -e "  4.1) Clic on  ${B}View Solutions${B_}  button and then"
  echo -e "  4.2) Clic on  ${B}Show Kata Test Cases${B_}  section"
  echo -e "  4.3) ${B}Update${B_} your ${B}local${B_} copy of the tests."
  echo -e "5) then run  ${B}${PROGRAM_NAME} -2${B_}  to commit your solution."
  echo

else
  echo -e "Workflow of  ${B}${PROGRAM_NAME}${B_}  not standard. Be careful."
  echo
fi
}


function createNewKataCW()
{
# https://docs.codewars.com/languages/haskell/
echo -e "${B}${LIB_U}${B_} LIB is being prepared."

cd "${LIBROOT}"

# Create, delete and update main files:
stack new "${LIB_L}" --resolver="${RESOLVER}"

cd "${LIBROOT}/${LIB_L}"

echo "## ${REF}" >> README.md
echo "## ${COMMENT}" >> README.md

# https://stackoverflow.com/questions/5178828/how-to-replace-all-lines-between-two-points-and-subtitute-it-with-some-text-in-s

# - hspec-codewars # https://github.com/codewars/hspec-codewars
# - hspec-formatters-codewars # https://github.com/codewars/hspec-formatters-codewars

# Add dependencies for QuickCheck and hspec
sed -i '/^dependencies:/,/^- base >= 4.7 && < 5/'\
'c\dependencies:\n\- base >= 4.7 && < 5\n'\
'- array\n'\
'- bytestring\n'\
'- containers\n'\
'- heredoc\n'\
'- hscolour\n'\
'- polyparse\n'\
'- pretty-show\n'\
'- unordered-containers\n'\
'- Cabal\n'\
'- HUnit\n'\
'- QuickCheck\n'\
'- attoparsec\n'\
'- haskell-src-exts\n'\
'- hspec\n'\
'- hspec-attoparsec\n'\
'- hspec-contrib\n'\
'- hspec-megaparsec\n'\
'- HUnit-approx\n'\
'- lens\n'\
'- megaparsec\n'\
'- mtl\n'\
'- parsec\n'\
'- persistent\n'\
'- persistent-sqlite\n'\
'- persistent-template\n'\
'- random\n'\
'- regex-pcre\n'\
'- regex-posix\n'\
'- regex-tdfa\n'\
'- split\n'\
'- text\n'\
'- transformers\n'\
'- vector' "package.yaml"

# delete app scafolding and add hspec-discover. Add five default extensions
sed -i '/^  source-dirs: src/,/^tests:'/\
'c\  source-dirs: src\n\nbuild-tools:\n- hspec-discover\n\n'\
'default-extensions:\n- InstanceSigs\n- TypeApplications\n'\
'- ScopedTypeVariables\n- GADTSyntax\n- PartialTypeSignatures\n\n'\
'- OverloadedStrings\n\n'\
'tests:' "package.yaml"

##### stack test

rm -rf app
rm src/Lib.hs

# Spec.hs:
cat > test/Spec.hs << EOF
{-# OPTIONS_GHC -F -pgmF hspec-discover #-}
EOF

# "${LIB_U}"Spec.hs:
cat > test/"${LIB_U}"Spec.hs << EOF
module ${LIB_U}Spec (main, spec) where

import Test.Hspec
import Test.QuickCheck

import ${LIB_U}

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  describe "Basic tests" $ do
    it "___DUMMY___" $ do
      id 42 \`shouldBe\` 42
EOF

# Lastly we'll add some shell content for the project to compile:
cat > src/${LIB_U}.hs << EOF
module ${LIB_U} where

${LIB_L} :: undefined
${LIB_L}  = undefined
EOF

# git:
cat > .gitignore << EOF
*~
*#
.#*
.cabal-sandbox
cabal.sandbox.config
.stack-work
/**/dist/
/**/TAGS
EOF

##############

stack test && git init
git add .gitignore *
git status
git commit -am "Create skeleton. Add ${LIB_U}.hs and ${LIB_U}Spec.hs"

echo
echo "Current git log:"
git log --graph --pretty=format:'%C(red)%h% %C(green) (%cd)%C(reset) %s %C(yellow)%d%C(reset)' --abbrev-commit --date=short

##############

# README.md    (GitLab / GitHub / ...)
# this file is placed into the .stack-work hidden directory.
# It would be helpful when you upload the repository to GitLab/GitHub/ ...

if [[ ${GITLAB_GITHUB^^}  == "GITLAB" ]] ; then
  GITLAB_GITHUB_USER=`eval "git config --get gitlab.user"`
elif [[ ${GITLAB_GITHUB^^}  == "GITHUB" ]] ; then
  GITLAB_GITHUB_USER=`eval "git config --get github.user"`
fi

cat > ${LIBROOT}/${LIB_L}/.stack-work/README.md << EOF
# ${LIB_U}
LIB: ${LIB_L} (BDD/TDD Style) - "${LIB_U}"

    git clone https://${GITLAB_GITHUB}.com/${GITLAB_GITHUB_USER}/${LIB_L}
    cd ${LIB_L}
    stack test
EOF

# cdargs:
(echo "${LIB_L} ${LIBROOT}/${LIB_L}" && cat ~/.cdargs) > ~/.cdargs_tmp && mv ~/.cdargs_tmp ~/.cdargs

# Some help:
echo
echo -e "${B}git${B_} is now particulary taking care of:"
echo -e "    ${LIBROOT}/${LIB_L}/${B}src/${LIB_U}.hs${B_}"
echo -e "    ${LIBROOT}/${LIB_L}/${B}test/${LIB_U}Spec.hs${B_}"
echo -e "    ${LIBROOT}/${LIB_L}/${B}package.yaml${B_}"
echo -e "    ${LIBROOT}/${LIB_L}/${B}stack.yaml${B_}"
echo
echo -e "Use command ${B}wk ${LIB_L}${B_} to edit all of them at once."
echo
echo -e "${U}Remember${B_}:"
echo -e "${B}cdargs${B_} or ${B}cdb${B_}  # (hit 'Enter' twice)  to visit your kata's directory"
echo -e "  (cd ${LIBROOT}/${LIB_U})"
echo -e "${B}stack test${B_} # Compile, and if success, run tests"
}

function watch_trigger()
{
  sleep 0.1
  echo ' ' > 'src/deleteThisFile.tmp'
  sleep 0.1
  rm 'src/deleteThisFile.tmp'
  sleep 0.1
}

function editor_and_terminals()
{

echo "export PS1='\[\e]0;HaskellKatas\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" | xclip -selection primary
xdotool key Shift+Insert

sleep 0.1

cd "${LIBROOT}/${LIB_L}"

# editor
emacs -T "${EDITOR_NAME}${LIB_U}" --no-splash --geometry="${GEOM_EMACS}" \
      "stack.yaml" "package.yaml" "src/${LIB_U}.hs" "test/${LIB_U}Spec.hs" \
      2>&1 &

sleep 1
# term 0 stack ghci (hidden)
xterm -xrm "xterm*allowTitleOps: false" -title "${TERMINAL_NAMES[0]}" -fa 'Monospace' -fs 11 -geometry ${GEOM_TERM0} &
sleep 0.2
# term 1 git diff
xterm -xrm "xterm*allowTitleOps: false" -title "${TERMINAL_NAMES[1]}" -fa 'Monospace' -fs 11 -geometry ${GEOM_TERM1} &
sleep 0.2
# term 2 stack build
xterm -xrm "xterm*allowTitleOps: false" -title "${TERMINAL_NAMES[2]}" -fa 'Monospace' -fs 11 -geometry ${GEOM_TERM2} &
sleep 0.2
# term 3 Command - git
xterm -xrm "xterm*allowTitleOps: false" -title "${TERMINAL_NAMES[3]}" -fa 'Monospace' -fs 11 -geometry ${GEOM_TERM3} -si &
sleep 1
##
# term 0 stack ghci (hidden)
TERMINAL_WINDOWS0=$( { xdotool search --name "${TERMINAL_NAMES[0]}"; } )
xdotool windowactivate --sync "${TERMINAL_WINDOWS0}" 2>/dev/null
sleep 0.2
echo  "stack exec -- ghci src/${LIB_U}.hs test/${LIB_U}Spec.hs" | xclip -selection primary
xdotool key Shift+Insert
sleep 1

# term 1 git diff
TERMINAL_WINDOWS1=$( { xdotool search --name "${TERMINAL_NAMES[1]}"; } )
xdotool windowactivate --sync "${TERMINAL_WINDOWS1}" 2>/dev/null
sleep 0.2

echo "while inotifywait -e modify package.yaml src/ test/; \
 do sleep 1 && clear && git diff package.yaml src/ test/ \
 && wmctrl -a '${EDITOR_NAME}'; done" | xclip -selection primary
xdotool key Shift+Insert
sleep 1

watch_trigger

# term 2 stack build
TERMINAL_WINDOWS2=$( { xdotool search --name "${TERMINAL_NAMES[2]}"; } )
xdotool windowactivate --sync "${TERMINAL_WINDOWS2}" 2>/dev/null
sleep 0.2
echo "stack build --test --file-watch --fast" | xclip -selection primary
xdotool key Shift+Insert
sleep 1

# term 3 Command - git
TERMINAL_WINDOWS3=$( { xdotool search --name "${TERMINAL_NAMES[3]}"; } )
xdotool windowactivate --sync "${TERMINAL_WINDOWS3}" 2>/dev/null
sleep 0.2
echo "${README}
${INSTRUCTIONS}" | xclip -selection primary
xdotool key Shift+Insert
sleep 0.2

}

# Program start

check "$@"

wmctrl -lp | grep "Command - git" >/dev/null 2>&1
if [ "$?" -eq 0 ] ; then
  quit_windows
fi

if [[ ${EDIT_EXISTING_KATA} != "YES" ]]; then
  if   [[ ${LIBROOT} == ${LIBROOT_CW} ]]; then
    createNewKataCW
  fi
fi

editor_and_terminals "${LIB_L}"
echo "Enjoy!"
