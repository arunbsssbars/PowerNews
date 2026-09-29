const fs = require('fs');
let code = fs.readFileSync('lib/screens/login_signup_screen.dart', 'utf8');

const target = `                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }
}`;

const replacement = `                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
        },
      ),
    ),
  );
  }
}`;

code = code.replace(target, replacement);
fs.writeFileSync('lib/screens/login_signup_screen.dart', code);
console.log('Fixed scaffold bracket');
