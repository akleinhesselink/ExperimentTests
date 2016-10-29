data{
  // training datalist, historical observations 
  int<lower=0> N;             // observations
  int<lower=0,upper=1> Y[N];  // observation vector
  vector[N] X;                // size vector
  int<lower=0> G;             // groups
  matrix[N, G] gm;            // group dummy variable matrix 
  int<lower=0> nyrs;          // years
  int<lower=0> yid[N];        // year id
  vector[N] W;                // crowding vector
}
parameters{
  vector[G] bg;               // varying group effects with first group as intercept 
  vector[nyrs] a_raw;
  real b1_mu;
  vector[nyrs] b1_raw;
  real<lower=0> sig_a;
  real<lower=0> sig_b1;
  real w;
}
transformed parameters{

  vector[nyrs] a;
  vector[nyrs] b1;
  vector[N] gint; 
  real mu[N];
  vector[N] crowdEff;

  gint <- gm*bg;
  crowdEff <- W*w;
  
  // reparamaterize the hierarchical parameters  
  a <- 0 + sig_a*a_raw;
  b1 <- b1_mu + sig_b1*b1_raw;

  for(n in 1:N){
    mu[n] <- inv_logit(gint[n] + a[yid[n]]  + b1[yid[n]]*X[n] + crowdEff[n]);
  }

}
model{
  // Priors
  bg ~ normal(0,10);
  b1_mu ~ normal(0,10);
  sig_a ~ cauchy(0,5);
  sig_b1 ~ cauchy(0,4);
  a_raw ~ normal(0,1);
  b1_raw ~ normal(0,1);
  w ~ normal(0,10);

  // Likelihood
  Y ~ binomial(1,mu);

}
generated quantities {

  // Section for calculating log_lik of fitted data 
  
  vector[N] log_lik; 
  
  for(n in 1:N){
    log_lik[n] <- bernoulli_log(Y[n], mu[n]); 
  }
  
}



