rm -rf .build/arm64-apple-macosx
compilationResults=$(swift build -Xswiftc -Xfrontend -Xswiftc -debug-time-function-bodies)

echo "Build output"
printf "$compilationResults" | tail -n 1

sortedLines=$(printf "$compilationResults" | sort -nr)

echo ""
echo "Here are the results"
printf "$sortedLines" | head -n 20

echo ""
echo "Here are the unique results"
printf "$sortedLines" | uniq | head -n 20