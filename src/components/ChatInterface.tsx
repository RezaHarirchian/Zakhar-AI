import React, { useState, useRef, useEffect } from 'react';
import {
  Box,
  TextField,
  IconButton,
  Paper,
  Typography,
  Container,
  useTheme,
  CircularProgress,
  Alert,
} from '@mui/material';
import { Send as SendIcon } from '@mui/icons-material';
import { motion, AnimatePresence } from 'framer-motion';
import axios from 'axios';
import { ErrorBoundary } from 'react-error-boundary';

interface Message {
  text: string;
  isUser: boolean;
  timestamp: Date;
}

const ErrorFallback: React.FC<{ error: Error }> = ({ error }) => {
  return (
    <Alert severity="error" sx={{ m: 2 }}>
      <Typography variant="h6">مشکلی پیش آمده</Typography>
      <Typography variant="body2">{error.message}</Typography>
    </Alert>
  );
};

const ChatInterface: React.FC = () => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isTyping, setIsTyping] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const theme = useTheme();

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const validateMessage = (message: string): string | null => {
    if (message.length > 1000) {
      return "پیام شما خیلی طولانی است. لطفاً آن را کوتاه‌تر کنید.";
    }
    if (!message.trim()) {
      return "پیام نمی‌تواند خالی باشد.";
    }
    return null;
  };

  const handleSend = async (retries = 3) => {
    const validationError = validateMessage(input);
    if (validationError) {
      setError(validationError);
      return;
    }

    const userMessage: Message = {
      text: input,
      isUser: true,
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);
    setIsTyping(true);
    setError(null);

    try {
      const response = await axios.post('http://localhost:8000/chat', {
        message: input,
        user_id: 'anonymous',
      });

      const aiMessage: Message = {
        text: response.data.response,
        isUser: false,
        timestamp: new Date(),
      };

      setMessages((prev) => [...prev, aiMessage]);
    } catch (error) {
      if (retries > 0) {
        await new Promise(resolve => setTimeout(resolve, 1000));
        return handleSend(retries - 1);
      }
      console.error('Error sending message:', error);
      setError('متأسفانه در پردازش درخواست شما مشکلی پیش آمده. لطفاً دوباره تلاش کنید.');
    } finally {
      setIsLoading(false);
      setIsTyping(false);
    }
  };

  return (
    <Container maxWidth="md" sx={{ height: 'calc(100vh - 64px)', py: 4 }}>
      <Paper
        elevation={3}
        sx={{
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          background: theme.palette.background.paper,
          borderRadius: 4,
          overflow: 'hidden',
          position: 'relative',
          '&::before': {
            content: '""',
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'linear-gradient(45deg, rgba(27,94,32,0.1) 0%, rgba(129,199,132,0.1) 100%)',
            zIndex: 0,
          },
        }}
      >
        <Box
          sx={{
            flexGrow: 1,
            overflowY: 'auto',
            p: 3,
            display: 'flex',
            flexDirection: 'column',
            gap: 2,
          }}
        >
          <AnimatePresence>
            {messages.map((message, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -20 }}
                transition={{ duration: 0.3 }}
              >
                <Box
                  sx={{
                    display: 'flex',
                    justifyContent: message.isUser ? 'flex-end' : 'flex-start',
                    mb: 2,
                  }}
                >
                  <Paper
                    elevation={2}
                    sx={{
                      p: 2,
                      maxWidth: '70%',
                      background: message.isUser
                        ? theme.palette.primary.main
                        : theme.palette.background.paper,
                      color: message.isUser
                        ? theme.palette.primary.contrastText
                        : theme.palette.text.primary,
                      borderRadius: 4,
                      position: 'relative',
                      '&::after': {
                        content: '""',
                        position: 'absolute',
                        bottom: 0,
                        [message.isUser ? 'right' : 'left']: -8,
                        width: 16,
                        height: 16,
                        background: message.isUser
                          ? theme.palette.primary.main
                          : theme.palette.background.paper,
                        transform: 'rotate(45deg)',
                      },
                    }}
                  >
                    <Typography variant="body1">{message.text}</Typography>
                    <Typography
                      variant="caption"
                      sx={{
                        display: 'block',
                        mt: 1,
                        opacity: 0.7,
                        textAlign: 'right',
                      }}
                    >
                      {message.timestamp.toLocaleTimeString()}
                    </Typography>
                  </Paper>
                </Box>
              </motion.div>
            ))}
          </AnimatePresence>
          {isTyping && (
            <Box sx={{ display: 'flex', justifyContent: 'flex-start', mb: 2 }}>
              <Paper
                elevation={2}
                sx={{
                  p: 2,
                  display: 'flex',
                  alignItems: 'center',
                  gap: 1,
                }}
              >
                <CircularProgress size={20} />
                <Typography>در حال تایپ...</Typography>
              </Paper>
            </Box>
          )}
          <div ref={messagesEndRef} />
        </Box>

        {error && (
          <Alert severity="error" sx={{ mx: 2, mt: 2 }}>
            {error}
          </Alert>
        )}

        <Box
          sx={{
            p: 2,
            borderTop: `1px solid ${theme.palette.divider}`,
            background: theme.palette.background.paper,
          }}
        >
          <Box
            sx={{
              display: 'flex',
              gap: 1,
              alignItems: 'center',
            }}
          >
            <TextField
              fullWidth
              variant="outlined"
              placeholder="پیام خود را بنویسید..."
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleSend()}
              disabled={isLoading}
              error={!!error}
              sx={{
                '& .MuiOutlinedInput-root': {
                  borderRadius: 4,
                },
              }}
            />
            <motion.div
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.95 }}
            >
              <IconButton
                color="primary"
                onClick={() => handleSend()}
                disabled={isLoading || !input.trim()}
                sx={{
                  background: theme.palette.primary.main,
                  color: theme.palette.primary.contrastText,
                  '&:hover': {
                    background: theme.palette.primary.dark,
                  },
                }}
              >
                {isLoading ? <CircularProgress size={24} color="inherit" /> : <SendIcon />}
              </IconButton>
            </motion.div>
          </Box>
        </Box>
      </Paper>
    </Container>
  );
};

const ChatInterfaceWithErrorBoundary: React.FC = () => {
  return (
    <ErrorBoundary FallbackComponent={ErrorFallback}>
      <ChatInterface />
    </ErrorBoundary>
  );
};

export default ChatInterfaceWithErrorBoundary; 