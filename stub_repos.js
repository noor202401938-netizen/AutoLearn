const fs = require('fs');
const path = require('path');

const repoDir = path.join(__dirname, 'lib', 'repository');

if (!fs.existsSync(repoDir)) {
  console.log('Repo dir not found');
  process.exit(0);
}

const files = fs.readdirSync(repoDir).filter(f => f.endsWith('_repository.dart') && f !== 'user_repository.dart' && f !== 'auth_repository.dart');

for (const file of files) {
  const filePath = path.join(repoDir, file);
  const className = file.replace('_repository.dart', '').split('_').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join('') + 'Repository';
  
  const content = `// lib/repository/${file}
import '../backend/api_client.dart';

class ${className} {
  final ApiClient _apiClient = ApiClient.instance;

  // TODO: Implement with actual ApiClient methods
}
`;

  fs.writeFileSync(filePath, content, 'utf8');
  console.log(`Stubbed ${file}`);
}
