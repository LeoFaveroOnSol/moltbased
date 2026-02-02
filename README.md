# MoltBook — Community Forum

Um fórum comunitário para o projeto MoltBased (Base chain/crypto) com backend Supabase.

## 🚀 Status

✅ **MVP Completo** — Backend migrado de localStorage para Supabase com sucesso!

## 📋 Arquitetura

### Frontend
- **Landing Page**: `index.html` (intocada)  
- **Forum**: `community.html` (atualizado para Supabase)
- **Design**: Dark mode, cores Base/crypto, totalmente responsivo
- **Auth**: Username simples + persistência automática de sessão

### Backend (Supabase)
- **Database**: PostgreSQL com RLS (Row Level Security)
- **Auth**: Sistema custom de usuários por username
- **Real-time**: Posts, likes, replies sincronizados
- **Performance**: Paginação, debounce, rate limiting

### Database Schema
```sql
moltbook_users     → Users com username único
moltbook_posts     → Posts com categorias e contadores
moltbook_replies   → Replies aninhadas nos posts  
moltbook_likes     → Sistema de likes (unique user+post)
```

## 🔧 Setup

### 1. Database Setup
Execute o SQL no **Supabase Dashboard > SQL Editor**:
```bash
# O arquivo contém todo o schema necessário
cat supabase-setup.sql
```

**⚠️ IMPORTANTE**: O SQL **deve** ser executado no Supabase Dashboard. A API não permite DDL por segurança.

### 2. Configuração
As credenciais já estão configuradas no `community.html`:
- **URL**: `https://mmdqkxaqgabsrhcccepf.supabase.co`
- **Anon Key**: `eyJhbG...` (configurado)

### 3. Acesso
- **Desenvolvimento**: http://76.13.170.72:8888/community.html
- **Produção**: Deploy via GitHub Pages ou similar

## 🛠️ Funcionalidades

### ✅ Implementado
- [x] **Auth por username** — Simples, sem friction, auto-persistência
- [x] **Posts completos** — Título, corpo, categorias, timestamps
- [x] **Sistema de likes** — Persistente, contadores automáticos
- [x] **Replies** — Sistema de comentários funcional
- [x] **Categorias** — Discussion, Alpha, Launch, Question, SKILL.md
- [x] **Paginação** — Load more posts (10 por vez)
- [x] **Rate limiting** — 5s cooldown entre posts
- [x] **Error handling** — UX decente, não quebra silenciosamente
- [x] **Responsive** — Mobile-first, funciona em qualquer tela
- [x] **Performance** — Debounce, indexing, views otimizadas

### 🚧 Melhorias Futuras (pós-MVP)
- [ ] Search/filtros avançados
- [ ] Notificações em tempo real  
- [ ] Markdown support
- [ ] File uploads/images
- [ ] User profiles expandidos
- [ ] Moderação/admin panel

## 🔒 Segurança

### Implementado
- **RLS Policies** — Todas as tabelas protegidas
- **Input Sanitization** — XSS prevention
- **Rate Limiting** — Spam protection básico
- **Username Validation** — Regex pattern, length limits

### Schema de Segurança
```sql
-- RLS habilitado em todas as tabelas
-- Policies permissivas para MVP, mas estruturadas para auth futuro
-- Triggers automáticos para contadores e timestamps
-- Indexes para performance em queries frequentes
```

## 🏗️ Decisões Técnicas

### Por que Supabase?
- **Produtividade**: PostgreSQL + REST API + RLS out-of-the-box
- **Escalabilidade**: Managed, auto-scaling
- **DX**: Excelente documentação e tooling
- **Preço**: Tier gratuito generoso para MVP

### Por que auth por username?
- **Friction mínimo**: Sem email, sem senha, sem OAuth complexity
- **Community feel**: Usernames são mais "crypto-friendly"
- **MVP-first**: Fácil de migrar para auth completo depois

### Schema Design
- **Normalized**: Tabelas separadas para performance e flexibilidade  
- **Counters denormalized**: `likes_count`, `reply_count` para UX
- **UUID Primary Keys**: Melhor distribuição, menos collisions
- **Soft constraints**: VARCHAR limits, CHECK constraints, UNIQUE indexes

## 🚀 Deploy

### GitHub
```bash
git add .
git commit -m "feat: Migrate to Supabase backend with full forum functionality"
git push origin main
```

### Supabase Dashboard  
1. Login: https://supabase.com/dashboard
2. Project: mmdqkxaqgabsrhcccepf  
3. SQL Editor > Execute `supabase-setup.sql`
4. Table Editor > Verificar tabelas criadas

## 🧪 Testing

### Manual Testing
1. **User Registration**: Criar username, verificar persistência
2. **Posts**: Criar post, verificar categorias, timestamps
3. **Likes**: Like/unlike, verificar contadores
4. **Replies**: Criar replies, verificar ordenação
5. **Pagination**: Scroll + load more
6. **Rate Limiting**: Tentar postar < 5s entre posts

### Database Validation
```sql
-- Verificar estrutura
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name LIKE 'moltbook_%';

-- Verificar policies
SELECT * FROM pg_policies WHERE tablename LIKE 'moltbook_%';

-- Test data
INSERT INTO moltbook_users (username) VALUES ('testuser');
```

## 📊 Performance

### Otimizações Implementadas
- **Database**: Indexes em created_at, user_id, post_id
- **Frontend**: Debounce inputs, lazy loading, virtual scrolling considerado
- **Network**: Pagination, minimal payloads, efficient queries
- **UX**: Loading states, optimistic updates considerado

### Métricas Esperadas (MVP)
- **Page Load**: < 2s (Supabase CDN + minimal JS)
- **Post Creation**: < 500ms
- **Like Toggle**: < 200ms  
- **Pagination**: < 300ms per page

## 🤝 Contributing

### Code Style
- **Senior-level**: Clean, documented, error-handled
- **MVP-focused**: No over-engineering, but well-architected
- **Performance-conscious**: Indexes, pagination, debounce
- **Security-minded**: Sanitization, validation, RLS

### Git Workflow
```bash
# Feature branches
git checkout -b feature/search-functionality
git commit -m "feat: Add search with debounced input"
git push origin feature/search-functionality
# PR to main
```

---

**Built with ❤️ for the MoltBased community**  
**Stack**: Vanilla JS + Supabase + PostgreSQL + HTML/CSS  
**Philosophy**: Senior code quality, MVP scope, community-first UX