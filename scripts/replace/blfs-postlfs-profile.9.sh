cat > /etc/profile.d/i18n.sh << "EOF2"
# Set up i18n variables
for i in $(locale); do
  unset ${i%=*}
done

if [[ "$TERM" = linux ]]; then
  export LANG=C.UTF-8
else
  export LANG=pt_PT.UTF-8
fi
EOF2
